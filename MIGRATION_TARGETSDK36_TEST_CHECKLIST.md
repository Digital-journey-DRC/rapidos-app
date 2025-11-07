# Checklist de Tests - Migration targetSdk 36

**Date de test:** _______________  
**Testeur:** _______________  
**Version testée:** _______________  
**Device(s) de test:** _______________

## Prérequis

- [ ] SDK Android 36 installé dans Android Studio
- [ ] Java 17 (JDK 17) configuré et vérifié (`java -version`)
- [ ] MAPBOX_DOWNLOADS_TOKEN configuré dans `android/gradle.properties`
- [ ] Flutter clean effectué
- [ ] `flutter pub get` exécuté avec succès

## Phase 1: Build & Compilation

### Build Debug
- [ ] `flutter build apk --debug` réussit sans erreur
- [ ] APK debug généré dans `build/app/outputs/flutter-apk/app-debug.apk`
- [ ] Taille de l'APK debug: _______________ MB

### Build Release
- [ ] `flutter build apk --release` réussit sans erreur
- [ ] APK release généré dans `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Taille de l'APK release: _______________ MB
- [ ] Signature de l'APK vérifiée (keystore correct)

### Build App Bundle (optionnel)
- [ ] `flutter build appbundle --release` réussit sans erreur
- [ ] AAB généré dans `build/app/outputs/bundle/release/app-release.aab`

## Phase 2: Installation & Démarrage

### Installation sur Device(s)
- [ ] Installation réussie sur Android 11 (API 30) - Device: _______________
- [ ] Installation réussie sur Android 12 (API 31) - Device: _______________
- [ ] Installation réussie sur Android 13 (API 33) - Device: _______________
- [ ] Installation réussie sur Android 14 (API 34) - Device: _______________
- [ ] Installation réussie sur Android 15 (API 35) - Device: _______________

### Démarrage de l'Application
- [ ] App démarre sans crash sur Android 11
- [ ] App démarre sans crash sur Android 12
- [ ] App démarre sans crash sur Android 13
- [ ] App démarre sans crash sur Android 14
- [ ] App démarre sans crash sur Android 15
- [ ] Temps de démarrage acceptable (< 3 secondes)

## Phase 3: Permissions Runtime

### Permission POST_NOTIFICATIONS (Android 13+)
- [ ] Sur Android 13+: La demande de permission `POST_NOTIFICATIONS` apparaît
- [ ] Sur Android 13+: L'utilisateur peut accepter la permission
- [ ] Sur Android 13+: L'utilisateur peut refuser la permission
- [ ] Sur Android 13+: Si refusée, les notifications ne s'affichent pas (comportement attendu)
- [ ] Sur Android < 13: Aucune demande de permission (automatique)

### Permission CAMERA
- [ ] Demande de permission caméra fonctionne
- [ ] Accès caméra fonctionne après acceptation
- [ ] Message d'erreur approprié si refusée

### Permissions READ_MEDIA_* (Android 13+)
- [ ] Sur Android 13+: `READ_MEDIA_IMAGES` demandée pour accès photos
- [ ] Sur Android 13+: `READ_MEDIA_VIDEO` demandée pour accès vidéos
- [ ] Sur Android 13+: Accès aux photos fonctionne après acceptation
- [ ] Sur Android 13+: Accès aux vidéos fonctionne après acceptation
- [ ] Sur Android < 13: `READ_EXTERNAL_STORAGE` utilisée (fallback)

### Permissions Localisation
- [ ] `ACCESS_FINE_LOCATION` demandée correctement
- [ ] `ACCESS_COARSE_LOCATION` utilisée si fine refusée
- [ ] Localisation fonctionne après acceptation
- [ ] Message d'erreur approprié si refusée

## Phase 4: Fonctionnalités Critiques

### Authentification
- [ ] Login fonctionne
- [ ] Logout fonctionne
- [ ] Session persistante fonctionne
- [ ] Token Firebase sauvegardé correctement

### Notifications
- [ ] **Notifications Firebase (Push):**
  - [ ] Réception de notifications push fonctionne
  - [ ] Affichage de notifications en foreground fonctionne
  - [ ] Affichage de notifications en background fonctionne
  - [ ] Clic sur notification ouvre l'app correctement
  - [ ] Token FCM récupéré et sauvegardé

- [ ] **Notifications Locales:**
  - [ ] Création de canal de notification fonctionne
  - [ ] Affichage de notification locale fonctionne
  - [ ] Son de notification fonctionne (notif.mp3)
  - [ ] Notification programmée fonctionne

### Upload & Stockage
- [ ] **Upload Photos:**
  - [ ] Sélection photo depuis galerie fonctionne
  - [ ] Prise photo avec caméra fonctionne
  - [ ] Upload vers Firebase Storage fonctionne
  - [ ] Affichage de progression upload fonctionne

- [ ] **Accès Fichiers:**
  - [ ] Lecture de fichiers fonctionne
  - [ ] Écriture de fichiers fonctionne (cache, etc.)
  - [ ] Partage de fichiers fonctionne (share_plus)

### Cartes & Navigation
- [ ] **Google Maps:**
  - [ ] Affichage de carte Google Maps fonctionne
  - [ ] Marqueurs sur carte fonctionnent
  - [ ] Géolocalisation sur carte fonctionne

- [ ] **Mapbox Navigation (si utilisée):**
  - [ ] Initialisation navigation fonctionne
  - [ ] Calcul d'itinéraire fonctionne
  - [ ] Navigation turn-by-turn fonctionne
  - [ ] Instructions vocales fonctionnent (si activées)

### Géolocalisation
- [ ] Récupération position actuelle fonctionne
- [ ] Suivi position en temps réel fonctionne
- [ ] Calcul distance fonctionne
- [ ] Background location fonctionne (si utilisée)

### Autres Fonctionnalités
- [ ] Partage de contenu (share_plus) fonctionne
- [ ] Ouverture de liens (url_launcher) fonctionne
- [ ] Deep links (app_links) fonctionnent
- [ ] Text-to-Speech (flutter_tts) fonctionne
- [ ] Audio (just_audio) fonctionne

## Phase 5: Background & Services

### Foreground Services
- [ ] Foreground service démarre correctement
- [ ] Notification de foreground service s'affiche
- [ ] Foreground service continue en arrière-plan
- [ ] Arrêt de foreground service fonctionne

### Background Tasks
- [ ] Tâches en arrière-plan fonctionnent
- [ ] Synchronisation données en arrière-plan fonctionne
- [ ] Notifications programmées fonctionnent après redémarrage

## Phase 6: Compatibilité & Performance

### Compatibilité Rétroactive
- [ ] **Android 11 (API 30):** Toutes fonctionnalités fonctionnent
- [ ] **Android 12 (API 31):** Toutes fonctionnalités fonctionnent
- [ ] **Android 13 (API 33):** Permissions runtime fonctionnent
- [ ] **Android 14 (API 34):** Toutes fonctionnalités fonctionnent
- [ ] **Android 15 (API 35):** Toutes fonctionnalités fonctionnent

### Performance
- [ ] Temps de démarrage acceptable (< 3 secondes)
- [ ] Navigation entre écrans fluide
- [ ] Pas de lag lors du scroll
- [ ] Consommation mémoire acceptable
- [ ] Pas de fuites mémoire détectées

### Stabilité
- [ ] Aucun crash lors des tests
- [ ] Aucune erreur dans les logs (`adb logcat`)
- [ ] Pas d'ANR (Application Not Responding)

## Phase 7: Tests Spécifiques SDK 36

### Comportements Android 15 (API 35)
- [ ] Toutes les fonctionnalités fonctionnent normalement
- [ ] Aucun comportement inattendu
- [ ] Performance identique ou meilleure qu'avant

### Edge Cases
- [ ] App fonctionne après mise à jour depuis ancienne version
- [ ] Permissions déjà accordées fonctionnent après mise à jour
- [ ] Données utilisateur préservées après mise à jour
- [ ] App fonctionne après redémarrage device

## Phase 8: Tests Play Store (si applicable)

### Pre-launch Report
- [ ] Pre-launch report Google Play: Aucune erreur critique
- [ ] Pre-launch report: Aucun crash détecté
- [ ] Pre-launch report: Compatibilité vérifiée

### Internal Testing
- [ ] APK/AAB uploadé sur Play Console
- [ ] Internal testing: Aucune erreur de validation
- [ ] Internal testing: Tests sur devices variés réussis

## Résultats Globaux

### Résumé
- **Tests réussis:** ___ / ___
- **Tests échoués:** ___ / ___
- **Tests bloquants:** ___ / ___

### Problèmes Identifiés
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

### Recommandations
- [ ] ✅ Prêt pour production
- [ ] ⚠️ Prêt avec réserves (voir problèmes ci-dessus)
- [ ] ❌ Non prêt (corrections nécessaires)

### Signatures
- **Testeur:** _______________ Date: _______________
- **Validateur:** _______________ Date: _______________

## Notes Additionnelles

_________________________________________________
_________________________________________________
_________________________________________________


