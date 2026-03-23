# LogisticoTrain deployment

Modele de deploiement Docker Compose de production pour le sujet LogisticoTrain.

## Contenu

- `docker-compose.yml` : pile complete avec services, profils, reseaux, volumes, configs, secrets et healthchecks.
- `deployment/mariadb` : bootstrap MariaDB et schema SQL.
- `deployment/mongodb` : bootstrap MongoDB et creation de l'utilisateur applicatif.
- `deployment/rabbitmq` : configuration RabbitMQ + STOMP.
- `deployment/restapi` : image Docker de production pour `RESTApi`.
- `deployment/wsapi` : bootstrap Maven/Java pour `RealtimeAPI`.
- `deployment/webapp` : build du frontend React.
- `deployment/nginx` : configuration Nginx de facade.
- `deployment/devtools` : bootstrap des outils d'administration.
- `deployment/secrets` : secrets utilises par la pile locale.

## Services

- `sqldatabase` : MariaDB 11.4
- `nosqldatabase` : MongoDB 7
- `broker` : RabbitMQ 3.13 + STOMP
- `restapi` : Python 3.11, image custom
- `wsapi` : Maven 3.9.9 + Java 21, source montee
- `front` : Nginx 1.27 Alpine
- `webapp` : Node 22, profil `builder`
- `phpmyadmin` et `mongo-express` : profil `dev-tool`

## Profils

- `builder` : active `webapp`
- `dev-tool` : active `phpmyadmin` et `mongo-express`

## Demarrage

Lancer toutes les commandes depuis le dossier qui contient vraiment `docker-compose.yml` :

`C:\Users\dylan\Downloads\Ressources du projet-20260318\LogisticoTrain_codebase\LogisticoTrain_codebase`

1. Construire le frontend :
   `docker compose --profile builder run --rm webapp`
2. Attendre la fin complete du build.
 
3. Demarrer la pile principale :
   `docker compose up -d`
4. Demarrer les outils d'admin :
   `docker compose --profile dev-tool up -d phpmyadmin mongo-express`
5. Verifier l'etat des conteneurs :
   `docker compose ps`
6. Lancer le smoke test :
   `powershell -ExecutionPolicy Bypass -File .\deployment\scripts\smoke-test.ps1`
7. Arreter la pile :
   `docker compose --profile dev-tool down`

## Acces

Utiliser de preference `127.0.0.1` dans le navigateur.

- application : `http://127.0.0.1/`
- healthcheck facade : `http://127.0.0.1/health`
- phpMyAdmin : `http://127.0.0.1:8081/`
- mongo-express : `http://127.0.0.1:8082/`

Si `localhost` affiche encore une ancienne erreur du navigateur, tester :

- `http://127.0.0.1/`
- `Ctrl+F5`
- un onglet prive
- un autre navigateur

## Verification rapide

Verifier d'abord que la pile repond en HTTP :

- `curl.exe -I http://127.0.0.1/`
- `curl.exe http://127.0.0.1/health`
- `curl.exe http://127.0.0.1/api/v1/voies`
- `curl.exe http://127.0.0.1/wsapi/websocket/info`

Resultat attendu :

- `http://127.0.0.1/` repond `200 OK`
- `/health` renvoie `{"status":"UP"}`
- `/api/v1/voies` repond sans erreur
- `/wsapi/websocket/info` repond sans erreur

## Verification manuelle du site

Une fois `http://127.0.0.1/` ouvert :

- la page d'accueil affiche le formulaire de connexion
- le champ nom d'utilisateur est saisissable
- un role peut etre choisi : `Operateur centre`, `Technicien centre` ou `Conducteur rame`
- le bouton `Valider` fonctionne
- apres validation, la barre de navigation affiche le nom utilisateur
- le changement de role via deconnexion / reconnexion fonctionne

Checks simples par role :

- `operateur` : acces a la vue `Controle du centre`
- `technicien` : acces a la vue `Gestion des taches`
- `conducteur` : acces aux vues `Entree de rame` et `Sortie de rame`

Le controle le plus fiable reste le smoke test car il verifie en plus :

- facade Nginx
- API REST
- WebSocket / STOMP
- base SQL
- base MongoDB
- broker RabbitMQ
- outils d'administration

## Choix techniques

- reseaux dedies `edge_net`, `sql_net`, `mongo_net`, `broker_net`
- seul `front` expose `80`
- outils d'admin exposes uniquement sur `127.0.0.1`
- volumes nommes uniquement, aucun volume anonyme
- `restapi` en image custom
- `wsapi` et `webapp` en bind mount source
- build frontend partage en lecture seule avec `front`
- `nginx.conf` et `enabled_plugins` geres via `configs`
- secrets hors du `docker-compose.yml`

## Gestion des secrets

Les fichiers de `deployment/secrets` sont deja renseignes pour l'environnement local courant.

Si les secrets sont modifies sur une pile deja initialisee, il faut reinitialiser les volumes de donnees avant redemarrage :

`docker compose --profile dev-tool down -v`

Puis relancer :

- `docker compose --profile builder run --rm webapp`
- `docker compose up -d`
- `docker compose --profile dev-tool up -d phpmyadmin mongo-express`

## Limites connues

- le frontend build correctement mais produit encore des warnings Sass/Webpack lies au projet
- `wsapi` peut mettre un peu plus de temps a etre totalement pret au premier demarrage Maven
- `mongo-express` est une image legacy maintenue ici uniquement pour respecter le sujet
- avec `docker compose` local, les options `uid` / `gid` / `mode` des `configs` sont ignorees par le moteur, sans bloquer le fonctionnement
