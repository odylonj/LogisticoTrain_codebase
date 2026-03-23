# Checklist Sujet

References :

- `CDC_LogisticoTrain.pdf`
- `CH2 - Docker.pdf`
- `command_manual.pdf`
- `rappel_NAT_PorForwarding_VBOX_figures.pdf`
- `CH3 - virtualisation aujourdhui.pdf`

## Etat actuel

Le deploiement est conforme au sujet et teste.

## Ce qui a ete fait

- correction de la structure Compose et des noms de services imposes
- mise en place des profils `builder` et `dev-tool`
- segmentation reseau et limitation des ports ouverts
- image custom de production pour `restapi`
- service Maven/Java avec source montee pour `wsapi`
- volumes nommes pour SQL, Mongo, broker, cache Maven, `target/` et build frontend
- healthchecks et depends_on avances
- secrets Docker et configurations Compose
- acces direct local a `phpmyadmin` et `mongo-express`
- smoke test complet valide
- secrets locaux de deploiement renseignes

## Conformite point par point

| Point du sujet | Statut | Commentaire |
|---|---|---|
| services imposes presents | Fait | `sqldatabase`, `nosqldatabase`, `broker`, `restapi`, `wsapi`, `front`, `webapp` |
| profils `builder` et `dev-tool` | Fait | `webapp` isole, outils d'admin isoles |
| versions minimales respectees | Fait | MariaDB 11.4, MongoDB 7, RabbitMQ 3.13, Python 3.11, Java 21, Maven 3.9.9, Node 22, Nginx Alpine |
| `restapi` en image custom | Fait | code embarque + bytecode Python precompile |
| `wsapi` avec code source monte | Fait | bind mount + cache Maven + `target/` persistants |
| healthchecks obligatoires | Fait | SQL, Mongo, broker, front |
| depends_on avances | Fait | conforme au sujet |
| restart policies | Fait | appliquees aux services critiques |
| volumes persistants sans anonymes | Fait | volumes nommes uniquement |
| build frontend partage avec `front` | Fait | volume `webapp_build` monte en RO |
| ports minimaux | Fait | `front` sur `80`, outils d'admin sur `127.0.0.1` |
| secrets hors compose | Fait | secrets fichiers sous `deployment/secrets` |
| init auto de la base SQL | Fait | script dans `deployment/mariadb/init` |
| reverse proxy Nginx pour REST et WS | Fait | facade unique pour l'application |
| outils d'admin hors `front` | Fait | acces direct local uniquement |

## Lecture selon le cours

- image vs conteneur : applique correctement la separation image immuable / runtime
- volumes nommes : utilises pour la persistance et les besoins de performance
- bind mounts : reserves au code source et aux scripts de bootstrap
- tmpfs : utilises pour les donnees runtime volatiles
- bridge / NAT / port mapping : ports mappes uniquement quand necessaire, loopback pour l'admin
- profils Compose : utilises pour les services non systematiques
- secrets Compose : utilises a la place de mots de passe en clair dans le YAML
- configs Compose : utilises pour les fichiers de configuration statiques

## Verifications executees

- `docker compose config`
- `docker compose --profile dev-tool config`
- `docker compose --profile builder run --rm webapp`
- `docker compose up -d`
- `docker compose --profile dev-tool up -d phpmyadmin mongo-express`
- `powershell -ExecutionPolicy Bypass -File .\deployment\scripts\smoke-test.ps1`

Resultat :

- build frontend OK
- pile Compose OK
- acces facade OK
- acces admin local OK
- flux REST OK
- flux STOMP / WebSocket OK

## Reste a faire

- faire une recette fonctionnelle plus large du frontend si une validation metier complete est attendue
- faire une rotation de secrets si le projet est deplace sur une autre machine ou rendu a un tiers
