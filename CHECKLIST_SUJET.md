# Checklist Sujet

Reference : [CDC_LogisticoTrain.pdf](c:/Users/dylan/Downloads/Ressources%20du%20projet-20260318/CDC_LogisticoTrain.pdf)

## Lecture Rapide

- `Fait` : conforme ou tres proche du sujet
- `Partiel` : fonctionne, mais avec un ecart ou une adaptation
- `Non fait` : non traite

## Conformite Point Par Point

| Point du sujet | Statut | Commentaire |
|---|---|---|
| `sqldatabase` MariaDB >= 11 | Fait | MariaDB 11.4 dans [docker-compose.yml](c:/Users/dylan/Downloads/Ressources%20du%20projet-20260318/LogisticoTrain_codebase/LogisticoTrain_codebase/docker-compose.yml) |
| `nosqldatabase` MongoDB >= 4.4 | Fait | MongoDB 7 |
| `broker` RabbitMQ >= 3.12 | Fait | RabbitMQ 3.13 avec plugin STOMP |
| `restapi` Python >= 3.11 | Fait | Image Python 3.11 custom |
| `wsapi` Java 21 + Maven 3 | Fait | Build via Maven 3.9.9, runtime Java 21 |
| `front` Nginx Alpine | Fait | Nginx 1.27 Alpine |
| service `webapp` sous profil dedie | Fait | profil `builder` |
| services `phpmyadmin` et `mongo-express` sous profil distinct | Fait | profil `dev-tool` |
| redemarrage auto DB/broker/apis/front | Fait | `restart: unless-stopped` |
| healthchecks DB/broker/front toutes les 10s, timeout 10s, retries 10 | Fait | conforme |
| api REST et Realtime attendent les DB saines | Fait | `depends_on` avec `service_healthy` |
| Realtime attend le broker sain | Fait | oui |
| front attend les 2 APIs | Fait | mieux: attend les 2 APIs `healthy` |
| image custom `RESTApi` avec code embarque | Fait | conforme a la recommandation |
| `RESTApi` avec bytecode Python precompile | Fait | `compileall` dans l'image |
| `RealtimeApi` monte en source avec cache Maven et `target` persistants | Partiel | choix different assume: image Java packagee de production, plus propre en runtime |
| aucun volume anonyme | Fait | volumes nommes uniquement |
| volumes de donnees pour DB | Fait | SQL, Mongo, RabbitMQ |
| persistance du build frontend | Fait | volume `webapp_build` |
| acces performant en lecture pour `front` sur build frontend | Fait | volume partage en lecture seule |
| `webapp` sur bridge Docker par defaut si possible | Fait | `network_mode: bridge` |
| isolation reseau DB et broker | Fait | `sql_net`, `mongo_net`, `broker_net` internes |
| moindre privilege sur ports ouverts | Fait | seules les entrees utiles sont publiees |
| secrets hors `docker-compose.yml` | Fait | secrets fichiers sous `deployment/secrets` |
| volumes/configs en lecture seule si possible | Fait | `front`, `restapi`, montages de config en RO |
| creation automatique du schema SQL au premier lancement | Fait | init SQL dans `deployment/mariadb/init/01-schema.sql` |
| build `webapp` accessible automatiquement au `front` en lecture seule | Fait | volume partage RO |
| livrable `docker-compose.yml` | Fait | present |
| livrable structure de config adaptee production | Fait | present sous `deployment/` |
| livrable `README.md` avec explications/bugs/limites | Fait | present |
| outils d'admin accessibles directement depuis leur port | Partiel | localement accessibles sur `127.0.0.1:8081` et `127.0.0.1:8082`, mais le passage se fait via la facade locale et non un bind natif fiable de leurs conteneurs sur cette machine |
| outils d'admin non accessibles via le serveur front nginx | Partiel | ecart connu lie a l'environnement Windows local ; voir [README.md](c:/Users/dylan/Downloads/Ressources%20du%20projet-20260318/LogisticoTrain_codebase/LogisticoTrain_codebase/README.md) |
| outils d'admin accessibles seulement depuis la machine locale | Fait | binds sur `127.0.0.1` pour `8081` et `8082` |

## Tests Realises

- `docker compose config`
- builds `restapi` et `wsapi`
- build frontend via `webapp`
- `powershell -ExecutionPolicy Bypass -File .\deployment\scripts\smoke-test.ps1`

Le smoke test valide :

- `front`
- `restapi`
- `wsapi`
- `phpMyAdmin`
- `mongo-express`
- un flux REST sur les voies
- un flux STOMP/WebSocket avec notification temps reel

## Ecarts Assumes

### 1. `wsapi` en image packagee

Le sujet recommande un montage source + Maven runtime pour faciliter le redeploiement rapide.
J'ai retenu une image multi-stage Java 21 car l'objectif ici est un deploiement de production, et non un workflow de developpement.

### 2. Outils d'admin et acces direct

Le sujet demande un acces direct local et hors `front`.
Sur cette machine Windows, la publication directe des ports `phpmyadmin` et `mongo-express` par leurs conteneurs n'etait pas fiable.
Le rendu reste exploitable, mais ce point doit etre annonce comme ecart connu.

## Reste A Faire

- remplacer tous les secrets d'exemple
- si besoin de conformite stricte au sujet, retenter un acces direct hors facade pour les outils d'admin sur l'environnement de rendu final
- faire une recette fonctionnelle front plus large
