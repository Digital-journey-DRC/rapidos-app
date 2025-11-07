# Audit Initial - Migration vers targetSdk 36

**Date:** 2025-01-XX
**Choix final:** targetSdk 36 (Android 15)
**Raison:** Le plugin `camera_android_camerax` nécessite SDK 36 minimum

## État Actuel

### Versions Build
- **Flutter:** 3.35.7
- **Dart:** 3.9.2
- **compileSdk:** Défini par Flutter (probablement 34)
- **targetSdk:** Défini par Flutter (probablement 34)
- **minSdk:** Défini par Flutter (probablement 21)
- **AGP (Android Gradle Plugin):** 8.2.0 ⚠️ (Flutter recommande ≥8.6.0)
- **Gradle:** 8.7 ✅
- **Kotlin:** 1.9.20 ⚠️ (Flutter recommande ≥2.1.0)
- **Java:** VERSION_1_8 ⚠️ (Requis: 17 pour AGP 8.x et SDK 35)

### Plugins Flutter Critiques
- `firebase_core: ^3.13.1` → 3.15.1 (disponible: 4.2.1)
- `firebase_messaging: ^15.2.6` → 15.2.9 (disponible: 16.0.4)
- `firebase_storage: ^12.4.7` → 12.4.9 (disponible: 13.0.4)
- `cloud_firestore: ^5.6.8` → 5.6.11 (disponible: 6.1.0)
- `image_picker: ^1.0.7` → 1.1.2 (disponible: 1.2.0)
- `camera: ^0.11.1` → 0.11.1 (disponible: 0.11.3)
- `permission_handler: ^11.3.0` → 11.4.0 (disponible: 12.0.1)
- `flutter_local_notifications: ^19.2.1` → 19.3.0 (disponible: 19.5.0)
- `geolocator: ^11.0.0` → 11.1.0 (disponible: 14.0.2)
- `google_maps_flutter: ^2.5.3` → 2.12.3 (disponible: 2.14.0)

### Plugin Local
- `flutter_mapbox_navigation` (local) - utilise compileSdk 33, targetSdk 33 ⚠️

### Permissions AndroidManifest.xml
**Actuelles:**
- `CAMERA` ✅
- `INTERNET` ✅
- `ACCESS_NETWORK_STATE` ✅
- `ACCESS_FINE_LOCATION` ✅
- `ACCESS_COARSE_LOCATION` ✅

**Manquantes pour API 33+ (targetSdk 35):**
- `POST_NOTIFICATIONS` ⚠️ (requis pour API 33+)
- `READ_MEDIA_IMAGES` ⚠️ (si accès photos, API 33+)
- `READ_MEDIA_VIDEO` ⚠️ (si accès vidéos, API 33+)

### Problèmes Identifiés

1. **AGP 8.2.0** - Flutter recommande ≥8.6.0
2. **Kotlin 1.9.20** - Flutter recommande ≥2.1.0
3. **Java 8** - Requis Java 17 pour AGP 8.x et SDK 35
4. **MAPBOX_DOWNLOADS_TOKEN** - Manquant (bloque le build)
5. **Permissions API 33+** - POST_NOTIFICATIONS manquante
6. **Plugin flutter_mapbox_navigation** - Utilise SDK 33, doit être mis à jour

## Plan de Migration

### Phase 1: Mises à jour Build
- [ ] AGP 8.2.0 → 8.6.0
- [ ] Kotlin 1.9.20 → 2.1.0
- [ ] Java 8 → 17
- [ ] compileSdk → 35
- [ ] targetSdk → 35
- [ ] Gradle 8.7 (déjà OK)

### Phase 2: Permissions & Manifest
- [ ] Ajouter POST_NOTIFICATIONS
- [ ] Ajouter READ_MEDIA_IMAGES (si nécessaire)
- [ ] Ajouter READ_MEDIA_VIDEO (si nécessaire)
- [ ] Vérifier foreground service permissions

### Phase 3: Plugins
- [ ] Mettre à jour flutter_mapbox_navigation (SDK 35)
- [ ] Vérifier compatibilité plugins Firebase
- [ ] Vérifier compatibilité permission_handler
- [ ] Vérifier compatibilité image_picker/camera

### Phase 4: Tests
- [ ] Build debug
- [ ] Build release
- [ ] Tests manuels sur devices Android 11-14

