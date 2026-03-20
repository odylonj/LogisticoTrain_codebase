# LogisticoTrain deployment

Cette racine contient un modele de deploiement Docker Compose de production pour le sujet LogisticoTrain.

Documents utiles :

- `SOUTENANCE.md` : trame orale et justification des choix
- `CHECKLIST_SUJET.md` : grille de conformite point par point par rapport au sujet

## Structure

- `docker-compose.yml`: pile complete avec services, profils, reseaux, volumes, secrets et healthchecks.
- `deployment/mariadb`: bootstrap MariaDB et schema SQL initialise au premier lancement.
- `deployment/mongodb`: bootstrap MongoDB et creation automatique d'un utilisateur applicatif.
- `deployment/rabbitmq`: activation du plugin STOMP et configuration du broker.
- `deployment/restapi`: image Docker de production pour `RESTApi`.
- `deployment/wsapi`: image Docker de production pour `RealtimeAPI`.
- `deployment/webapp`: script de build du frontend React.
- `deployment/nginx`: configuration Nginx de facade.
- `deployment/secrets`: fichiers de secrets d'exemple a remplacer avant usage reel.

## Services

- `sqldatabase`: MariaDB 11.4, volume persistant, schema initialise automatiquement.
- `nosqldatabase`: MongoDB 7, volume persistant, utilisateur applicatif cree au premier lancement.
- `broker`: RabbitMQ 3.13 avec plugin STOMP.
- `restapi`: image Python 3.11 embarquant le code source et des bytecodes precompiles.
- `wsapi`: image Java 21 embarquant un jar Spring Boot package.
- `front`: Nginx en facade HTTP, sert le build frontend et reverse-proxy les deux APIs ainsi que les outils d'admin.
- `webapp`: build Node 22 du frontend, en profil separe.
- `phpmyadmin` et `mongo-express`: outils d'admin reserves au profil `dev-tool`, exposes via la facade Nginx.
  acces borne a `127.0.0.1` pour les ports d'admin

## Profils

- `builder`: n'active que `webapp`.
- `dev-tool`: active `phpmyadmin` et `mongo-express`.

## Utilisation

1. Remplacer les fichiers de `deployment/secrets/*.txt` par de vraies valeurs.
2. Construire le frontend:
   `docker compose --profile builder run --rm webapp`
3. Demarrer la pile principale:
   `docker compose up -d sqldatabase nosqldatabase broker restapi wsapi front`
4. Demarrer les outils d'admin si besoin:
   `docker compose --profile dev-tool up -d phpmyadmin mongo-express`
5. Lancer le smoke test complet:
   `powershell -ExecutionPolicy Bypass -File .\deployment\scripts\smoke-test.ps1`

Acces prevus:

- application: `http://localhost/`
- phpMyAdmin: `http://localhost:8081/`
- mongo-express: `http://localhost:8082/`
  authentification HTTP via `deployment/secrets/mongo_express_basic_auth_user.txt` et `deployment/secrets/mongo_express_basic_auth_password.txt`

## Choix de deploiement

- reseaux segmentes:
  `edge_net` pour la facade et les APIs, `sql_net` pour MariaDB, `mongo_net` pour MongoDB, `broker_net` pour RabbitMQ
- pas d'exposition host pour les bases, le broker et les APIs
- volumes nommes uniquement, aucun volume anonyme
- `webapp` sur le bridge Docker par defaut via `network_mode: bridge`
- secrets hors du `docker-compose.yml`, lus depuis des fichiers montes
- `front`, `restapi` et les montages de configuration sont en lecture seule quand c'est possible
- `front` publie aussi `8081` et `8082` et relaie ces ports vers les outils d'admin du profil `dev-tool`
- `mongo-express` n'utilise plus les identifiants HTTP par defaut de l'image; ils sont injectes depuis des secrets
- `wsapi` est build en multi-stage puis execute sur une image JRE, sans Maven en runtime

## Limitations connues

- Le build frontend repose sur Node 22 comme demande par le sujet et il fonctionne, mais le projet reference encore `node-sass` et produit plusieurs warnings Sass/Webpack.
- `mongo-express` est maintenu uniquement pour respecter le sujet; l'image officielle indique un etat deprecation.
- Sur cette machine Windows, la publication directe des ports sur `phpmyadmin` et `mongo-express` n'etait pas fiable; l'acces passe donc par la facade Nginx, ce qui reste fonctionnel.
- Le smoke test couvre maintenant un flux REST et un flux STOMP/WebSocket minimaux, mais pas l'ensemble des parcours fonctionnels du front.
