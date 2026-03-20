# Soutenance LogisticoTrain

## Version courte

Le sujet demandait de transformer le systeme LogisticoTrain en un deploiement Docker Compose de production.
Le systeme repose sur 2 bases de donnees, 2 APIs, un broker temps reel, un builder frontend et un serveur Nginx de facade.

J'ai donc construit une pile Compose complete avec :

- `sqldatabase` sur MariaDB 11.4
- `nosqldatabase` sur MongoDB 7
- `broker` sur RabbitMQ 3.13 avec STOMP
- `restapi` sur une image Python 3.11 de production
- `wsapi` sur une image Java 21 build multi-stage
- `front` sur Nginx Alpine
- `webapp` sous profil `builder`
- `phpmyadmin` et `mongo-express` sous profil `dev-tool`

L'objectif etait d'avoir un deploiement plus maintenable, plus securise et plus resilient que l'existant.

## Ce Que J'ai Fait

### Architecture

- segmentation reseau entre facade, SQL, Mongo et broker
- volumes nommes pour les donnees persistantes
- secrets externalises dans `deployment/secrets`
- healthchecks et dependances avancees entre services
- facade Nginx pour servir le frontend et proxyfier les APIs

### Productionisation

- `RESTApi` tourne sous Waitress et non plus avec le serveur Flask de dev
- `RealtimeAPI` tourne dans une image Java packagee, sans Maven en runtime
- ajout d'endpoints `/health` pour `restapi` et `wsapi`
- ajout d'un smoke test complet dans `deployment/scripts/smoke-test.ps1`

### Validation

J'ai valide :

- le build compose
- le build frontend
- le demarrage complet de la pile
- les healthchecks
- un flux REST reel sur les voies
- un flux STOMP/WebSocket reel avec notification sur `/topic/rameaccess`
- l'acces a `phpMyAdmin` et `mongo-express`

## Pourquoi Ces Choix

### Pourquoi une image custom pour `restapi`

Le sujet le recommande explicitement car le code est stable.
Cela permet de precompiler Python et d'eviter un runtime de developpement.

### Pourquoi une image custom pour `wsapi`

Le sujet suggere plutot un montage de source + Maven, mais c'est un conseil, pas une obligation.
Pour un rendu "production", une image Java packagee est plus propre :

- pas de Maven en runtime
- demarrage plus propre
- moins de variabilite
- plus proche d'un vrai deploiement exploitable

J'ai donc privilegie la logique de production plutot que la logique de rechargement rapide de developpement.

### Pourquoi les outils d'admin passent par un port local borne

Le sujet demande un acces local uniquement.
Sur cette machine Windows, la publication directe des ports des conteneurs `phpmyadmin` et `mongo-express` n'etait pas fiable.
J'ai donc conserve un acces local borne sur `127.0.0.1:8081` et `127.0.0.1:8082`.

## Ce Que Je Dirais Si On Me Demande "Est-Ce Que C'est Fini ?"

Oui pour le socle de deploiement.
Non si on parle d'une recette fonctionnelle complete du produit.

En pratique :

- le deploiement Docker Compose est fait
- la pile est testee
- la resilience et la securite de base sont en place
- il reste surtout des vraies valeurs de secrets et une recette fonctionnelle plus large

## Questions Probables

### Quels sont les points forts du rendu

- stack complete et demarrable
- vraies validations techniques
- productionisation des 2 APIs
- smoke test reutilisable

### Quels sont les ecarts par rapport au sujet

- `wsapi` est package en image au lieu d'etre compile a chaud via Maven runtime
- les outils d'admin restent exposes localement seulement, mais pas via un mapping direct natif de leurs propres conteneurs sur cette machine

### Qu'est-ce qu'il reste a faire en priorite

- remplacer les secrets placeholders
- faire une recette fonctionnelle front plus complete
- ajouter HTTPS si on veut aller jusqu'au rendu "pre-prod"
