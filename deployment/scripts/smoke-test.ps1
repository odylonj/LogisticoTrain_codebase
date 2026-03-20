param(
    [string]$BaseUrl = "http://127.0.0.1",
    [switch]$SkipAdminTools
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "==> $Message"
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body,
        [hashtable]$Headers
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($Headers) {
        $params.Headers = $Headers
    }

    if ($null -ne $Body) {
        $params.ContentType = "application/json"
        $params.Body = ($Body | ConvertTo-Json -Compress)
    }

    Invoke-RestMethod @params
}

function Wait-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][scriptblock]$Predicate,
        [int]$TimeoutSeconds = 20
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $response = Invoke-RestMethod -Uri $Uri -ErrorAction Stop
            if (& $Predicate $response) {
                return $response
            }
        } catch {
        }
        Start-Sleep -Milliseconds 500
    }

    throw "Timeout while waiting for $Uri"
}

function Assert-StatusCode {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [int]$Expected = 200,
        [hashtable]$Headers
    )

    $params = @{
        Uri         = $Uri
        Method      = "GET"
        ErrorAction = "Stop"
        UseBasicParsing = $true
    }
    if ($Headers) {
        $params.Headers = $Headers
    }

    $response = Invoke-WebRequest @params
    if ($response.StatusCode -ne $Expected) {
        throw "Unexpected status code for ${Uri}: $($response.StatusCode)"
    }
}

function New-StompClient {
    param(
        [Parameter(Mandatory = $true)][string]$WebSocketUri
    )

    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [Threading.CancellationTokenSource]::new()
    $client.ConnectAsync([Uri]$WebSocketUri, $cts.Token).GetAwaiter().GetResult() | Out-Null

    $buffer = New-Object byte[] 4096
    $segment = [ArraySegment[byte]]::new($buffer)
    $client.ReceiveAsync($segment, $cts.Token).GetAwaiter().GetResult() | Out-Null

    [pscustomobject]@{
        Client = $client
        Token  = $cts
    }
}

function Send-SockJsFrame {
    param(
        [Parameter(Mandatory = $true)]$StompClient,
        [Parameter(Mandatory = $true)][string]$FrameText
    )

    $payload = ConvertTo-Json @($FrameText) -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $segment = [ArraySegment[byte]]::new($bytes)
    $StompClient.Client.SendAsync(
        $segment,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        $StompClient.Token.Token
    ).GetAwaiter().GetResult() | Out-Null
}

function Receive-SockJsMessages {
    param(
        [Parameter(Mandatory = $true)]$StompClient,
        [int]$TimeoutSeconds = 10
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $buffer = New-Object byte[] 8192
        $segment = [ArraySegment[byte]]::new($buffer)
        $receiveCts = [Threading.CancellationTokenSource]::new()
        $receiveCts.CancelAfter(1000)

        try {
            $result = $StompClient.Client.ReceiveAsync($segment, $receiveCts.Token).GetAwaiter().GetResult()
        } catch {
            continue
        }

        $text = [Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
        if (-not $text -or $text -eq "h" -or $text -eq "o") {
            continue
        }

        if ($text.StartsWith("a")) {
            $decoded = ConvertFrom-Json $text.Substring(1)
            if ($decoded -is [string]) {
                return @($decoded)
            }
            return @($decoded)
        }
    }

    return @()
}

function Send-StompFrame {
    param(
        [Parameter(Mandatory = $true)]$StompClient,
        [Parameter(Mandatory = $true)][string]$Frame
    )

    Send-SockJsFrame -StompClient $StompClient -FrameText $Frame
}

function Read-SecretFile {
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )

    $secretPath = Join-Path $PSScriptRoot "..\\secrets\\$Name"
    (Get-Content $secretPath -Raw).Trim()
}

function Remove-TestVoie {
    param([int]$VoieNumber)
    try {
        Invoke-WebRequest -Method Delete -Uri "$BaseUrl/api/v1/voies/$VoieNumber" -UseBasicParsing -ErrorAction Stop | Out-Null
    } catch {
    }
}

Write-Step "Validation HTTP de base"
Assert-StatusCode -Uri "$BaseUrl/health"
Assert-StatusCode -Uri "$BaseUrl/api/v1/voies"
Assert-StatusCode -Uri "$BaseUrl/wsapi/websocket/info"

if (-not $SkipAdminTools) {
    Write-Step "Validation des outils d'administration"
    Assert-StatusCode -Uri "${BaseUrl}:8081/"

    $mongoExpressUser = Read-SecretFile -Name "mongo_express_basic_auth_user.txt"
    $mongoExpressPassword = Read-SecretFile -Name "mongo_express_basic_auth_password.txt"
    $basicAuthBytes = [Text.Encoding]::ASCII.GetBytes("$mongoExpressUser`:$mongoExpressPassword")
    $basicAuthHeader = @{
        Authorization = "Basic " + [Convert]::ToBase64String($basicAuthBytes)
    }
    Assert-StatusCode -Uri "${BaseUrl}:8082/" -Headers $basicAuthHeader
}

$testNumSerie = ("SMK{0}" -f (Get-Random -Minimum 1000 -Maximum 9999))
$testVoie = $null
$stompClient = $null

try {
    Write-Step "Validation STOMP/WebSocket et flux metier minimal"

    for ($candidate = 900; $candidate -lt 999; $candidate++) {
        try {
            $createdVoie = Invoke-JsonRequest -Method "POST" -Uri "$BaseUrl/api/v1/voies" -Body @{
                numVoie    = $candidate
                interdite  = $false
            }
            $testVoie = [int]$createdVoie.numVoie
            break
        } catch {
        }
    }

    if ($null -eq $testVoie) {
        throw "Impossible de reserver une voie de test libre"
    }

    $stompClient = New-StompClient -WebSocketUri ("ws://127.0.0.1/wsapi/websocket/000/{0}/websocket" -f ([Guid]::NewGuid().ToString("N")))

    Send-StompFrame -StompClient $stompClient -Frame ("CONNECT`naccept-version:1.2`nheart-beat:0,0`n`n{0}" -f [char]0)
    $connectedFrames = Receive-SockJsMessages -StompClient $stompClient -TimeoutSeconds 10
    if (-not ($connectedFrames | Where-Object { $_ -match "^CONNECTED" })) {
        throw "Handshake STOMP invalide"
    }

    Send-StompFrame -StompClient $stompClient -Frame ("SUBSCRIBE`nid:sub-0`ndestination:/topic/rameaccess`n`n{0}" -f [char]0)

    $entranceBody = @{
        messageType = "entranceRequest"
        numSerie    = $testNumSerie
        auteur      = "smoketest"
        typeRame    = "ZTER"
        taches      = @("controle technique")
    } | ConvertTo-Json -Compress
    Send-StompFrame -StompClient $stompClient -Frame ("SEND`ndestination:/app/rameaccess`ncontent-type:application/json`ncontent-length:{0}`n`n{1}{2}" -f ([Text.Encoding]::UTF8.GetByteCount($entranceBody)), $entranceBody, [char]0)

    Wait-Json -Uri "$BaseUrl/api/v1/rames/${testNumSerie}?details" -Predicate {
        param($rame)
        $rame.numSerie -eq $testNumSerie
    } -TimeoutSeconds 25 | Out-Null

    $acceptBody = @{
        messageType = "entranceAnswer"
        numSerie    = $testNumSerie
        auteur      = "smoketest"
        accept      = $true
        voie        = $testVoie
    } | ConvertTo-Json -Compress
    Send-StompFrame -StompClient $stompClient -Frame ("SEND`ndestination:/app/rameaccess.{0}`ncontent-type:application/json`ncontent-length:{1}`n`n{2}{3}" -f $testNumSerie, ([Text.Encoding]::UTF8.GetByteCount($acceptBody)), $acceptBody, [char]0)

    Wait-Json -Uri "$BaseUrl/api/v1/rames/${testNumSerie}?details" -Predicate {
        param($rame)
        $rame.voie -eq $testVoie
    } -TimeoutSeconds 25 | Out-Null

    Invoke-JsonRequest -Method "POST" -Uri "$BaseUrl/api/v1/rames/$testNumSerie/actions" -Body @{
        action = "realTaches"
        auteur = "smoketest"
        taches = @(1)
    } | Out-Null

    Invoke-JsonRequest -Method "PUT" -Uri "$BaseUrl/wsapi/rest/rames/remove-order" -Body @{
        messageType = "remove"
        numSerie    = $testNumSerie
        auteur      = "smoketest"
        voie        = $testVoie
    } | Out-Null

    $topicFrames = Receive-SockJsMessages -StompClient $stompClient -TimeoutSeconds 15
    $topicFrame = $topicFrames | Where-Object { $_ -match "^MESSAGE" } | Select-Object -First 1
    if (-not $topicFrame) {
        throw "Aucune notification /topic/rameaccess recue"
    }

    Write-Step "Smoke test temps reel valide"
} finally {
    if ($stompClient) {
        try {
            $stompClient.Client.Dispose()
        } catch {
        }
    }

    if ($testVoie) {
        Start-Sleep -Seconds 1
        Remove-TestVoie -VoieNumber $testVoie
    }
}

Write-Step "Smoke test termine avec succes"
