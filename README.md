# LogisticoTrain - README de deploiement

Ce depot correspond au projet de deploiement Docker Compose de LogisticoTrain.

L'objectif du rendu est de fournir tout ce qui est necessaire pour deployer la stack, sans embarquer les dependances generees localement comme `node_modules`.

## Contenu minimal attendu dans le rendu

Le rendu doit au minimum contenir :

- `docker-compose.yml`
- `deployment/nginx/nginx.conf`
- `deployment/restapi/Dockerfile`
- la configuration adaptee des services de deploiement dans `deployment/`
- un `README.md` expliquant le deploiement et ce que l'administrateur doit gerer

Dans ce projet, il faut conserver aussi les sources necessaires au deploiement :

- `RESTApi/` car l'image `restapi` est construite a partir de ce code
- `RealtimeAPI/` car `wsapi` est execute a partir de ce code monte dans le conteneur
- `app/` car `webapp` construit le frontend a partir de ce code

## Ce qu'il ne faut pas livrer

Ne pas inclure dans le rendu :

- `app/node_modules/`
- les builds locaux jetables si presents
- les caches de dependances locaux
- les volumes Docker
- les artefacts temporaires

Le deploiement reconstruit ce qui est necessaire au runtime ou via les volumes Docker nommes.

## Arborescence utile du projet

- `docker-compose.yml` : definition complete de la stack
- `deployment/nginx/` : configuration Nginx
- `deployment/restapi/` : Dockerfile et bootstrap de l'API Python
- `deployment/wsapi/` : bootstrap du service Java
- `deployment/webapp/` : script de build du frontend
- `deployment/mariadb/` : init SQL et bootstrap MariaDB
- `deployment/mongodb/` : init MongoDB et bootstrap
- `deployment/rabbitmq/` : bootstrap RabbitMQ et plugins
- `deployment/devtools/` : bootstrap `phpmyadmin` et `mongo-express`
- `deployment/secrets/` : secrets utilises par la stack

## Services deployes

- `sqldatabase` : MariaDB 11.4
- `nosqldatabase` : MongoDB 7
- `broker` : RabbitMQ 3.13 avec STOMP
- `restapi` : API Python 3.11 en image custom
- `wsapi` : service Java 21 / Maven 3.9.9 monte depuis le code source
- `front` : Nginx 1.27 Alpine
- `webapp` : builder Node 22 pour le frontend
- `phpmyadmin` : outil SQL optionnel via profil `dev-tool`
- `mongo-express` : outil Mongo optionnel via profil `dev-tool`

## Profils Compose

- `builder` : active `webapp`
- `dev-tool` : active `phpmyadmin` et `mongo-express`

## Ce que l'administrateur doit gerer

L'administrateur doit gerer :

- les secrets dans `deployment/secrets/`
- le lancement initial du build frontend
- le demarrage et l'arret de la stack
- la verification de l'etat des conteneurs
- l'activation eventuelle des outils d'administration
- la rotation des secrets si les mots de passe changent
- la reinitialisation des volumes si on change les secrets d'une base deja initialisee

## Gestion des secrets

Les services lisent leurs secrets via Docker Compose, depuis les fichiers de `deployment/secrets/`.

Si le rendu doit etre executable directement par le correcteur, ce dossier doit contenir des valeurs valides.

Si le rendu est destine a etre diffuse plus largement, il vaut mieux remplacer ces valeurs par des secrets d'exemple et indiquer a l'administrateur de les renseigner avant lancement.

Si les secrets de base de donnees ou du broker changent apres une premiere initialisation, il faut recreer les volumes de donnees.

## Procedure de deploiement

Toutes les commandes suivantes doivent etre lancees depuis le dossier qui contient `docker-compose.yml`.

1. Construire le frontend :

```powershell
docker compose --profile builder run --rm webapp
```

2. Demarrer la pile principale :

```powershell
docker compose up -d
```

3. Demarrer les outils d'administration si necessaire :

```powershell
docker compose --profile dev-tool up -d phpmyadmin mongo-express
```

4. Verifier l'etat de la pile :

```powershell
docker compose ps
```

5. Lancer le smoke test :

```powershell
powershell -ExecutionPolicy Bypass -File .\deployment\scripts\smoke-test.ps1
```

## Acces

Utiliser de preference `127.0.0.1` dans le navigateur :

- application : `http://127.0.0.1/`
- health facade : `http://127.0.0.1/health`
- phpMyAdmin : `http://127.0.0.1:8081/`
- mongo-express : `http://127.0.0.1:8082/`

## Administration courante

Arreter toute la pile :

```powershell
docker compose --profile dev-tool down
```

Arreter et supprimer aussi les volumes :

```powershell
docker compose --profile dev-tool down -v
```

Cette seconde commande efface les donnees persistantes et doit etre reservee a une reinitialisation complete.

## Verification attendue

La stack est consideree correctement deployee si :

- `docker compose ps` montre les services critiques demarres
- `front` repond sur `http://127.0.0.1/`
- `/health` repond correctement
- le smoke test se termine avec succes
- `phpmyadmin` et `mongo-express` sont accessibles quand le profil `dev-tool` est actif

## Choix d'architecture a signaler

- `front` est la facade unique exposee sur le port `80`
- les bases et le broker ne sont pas exposes publiquement
- les communications backend passent par les reseaux Docker internes
- `restapi` utilise une image custom
- `wsapi` et `webapp` fonctionnent a partir du code source monte
- les secrets sont separes du `docker-compose.yml`
- les volumes nommes evitent les volumes anonymes et permettent la persistance

## Limites connues

- le premier build frontend peut etre long
- `wsapi` peut etre plus lent au premier demarrage a cause du telechargement Maven
- le frontend produit encore des warnings Sass/Webpack lies au projet source
- avec `docker compose` local, les options `uid` / `gid` / `mode` des `configs` peuvent etre ignorees par le moteur sans casser le fonctionnement
