# LogisticoTrain deployment

Cette racine contient un modele de deploiement Docker Compose de production pour le sujet LogisticoTrain.

## Structure

- `docker-compose.yml`: pile complete avec services, profils, reseaux, volumes, secrets et healthchecks.
- `deployment/mariadb`: bootstrap MariaDB et schema SQL initialise au premier lancement.
- `deployment/mongodb`: bootstrap MongoDB et creation automatique d'un utilisateur applicatif.
- `deployment/rabbitmq`: activation du plugin STOMP et configuration du broker.
- `deployment/restapi`: image Docker de production pour `RESTApi`.
- `deployment/wsapi`: script de lancement Maven/Spring pour `RealtimeAPI`.
- `deployment/webapp`: script de build du frontend React.
- `deployment/nginx`: configuration Nginx de facade.
- `deployment/secrets`: fichiers de secrets d'exemple a remplacer avant usage reel.

## Services

- `sqldatabase`: MariaDB 11.4, volume persistant, schema initialise automatiquement.
- `nosqldatabase`: MongoDB 7, volume persistant, utilisateur applicatif cree au premier lancement.
- `broker`: RabbitMQ 3.13 avec plugin STOMP.
- `restapi`: image Python 3.11 embarquant le code source et des bytecodes precompiles.
- `wsapi`: execution de `RealtimeAPI` sur Maven + Java 21 avec code source monte.
- `front`: Nginx en facade HTTP, sert le build frontend et reverse-proxy les deux APIs.
- `webapp`: build Node 22 du frontend, en profil separe.
- `phpmyadmin` et `mongo-express`: outils d'admin reserves au profil `dev-tool` et exposes uniquement en `127.0.0.1`.

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

Acces prevus:

- application: `http://localhost/`
- phpMyAdmin: `http://127.0.0.1:8081/`
- mongo-express: `http://127.0.0.1:8082/`

## Choix de deploiement

- reseaux segmentes:
  `edge_net` pour la facade et les APIs, `sql_net` pour MariaDB, `mongo_net` pour MongoDB, `broker_net` pour RabbitMQ
- pas d'exposition host pour les bases, le broker et les APIs
- volumes nommes uniquement, aucun volume anonyme
- `webapp` sur le bridge Docker par defaut via `network_mode: bridge`
- secrets hors du `docker-compose.yml`, lus depuis des fichiers montes
- `front`, `restapi` et les montages de configuration sont en lecture seule quand c'est possible

## Limitations connues

- Le build frontend repose sur Node 22 comme demande par le sujet, mais le projet reference encore `node-sass`. Je n'ai pas pu executer le build ici pour verifier sa compatibilite reelle.
- `mongo-express` est maintenu uniquement pour respecter le sujet; l'image officielle indique un etat deprecation.
- Je n'ai pas lance les conteneurs ni telecharge les images. La validation effectuee ici est une validation statique de la composition et des fichiers.
