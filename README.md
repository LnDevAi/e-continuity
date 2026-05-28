# E-Continuity — E-DÉFENCE

SaaS Cloud de Continuité Numérique — Synchronisation multi-appareils + Kill Switch sécurisé.

## Fonctionnalités
- Synchronisation transparente de l'environnement (configs, fichiers)
- Explorateur P2P bidirectionnel (PC ↔ Smartphone via WebRTC)
- Presse-papier universel (partage instantané entre appareils)
- Kill Switch & Lockdown (verrouillage ou effacement sécurisé à distance)

## Stack
Flutter (Android, iOS, Windows, macOS) · NestJS · PostgreSQL · Redis · WebRTC · Libsodium · gRPC

## Démarrage
```bash
docker-compose up -d
cd backend && npm install && npx prisma migrate dev && npm run start:dev
cd mobile && flutter pub get && flutter run
```
