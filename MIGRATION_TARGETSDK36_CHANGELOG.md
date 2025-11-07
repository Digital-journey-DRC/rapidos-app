# CHANGELOG - Migration vers targetSdk 36

**Date:** 2025-01-XX  
**Choix final:** **targetSdk 36** (Android 15)  
**Raison:** Le plugin `camera_android_camerax` nécessite SDK 36 minimum.

## Résumé des Changements

### Versions Mises à Jour

| Composant | Avant | Après | Raison |
|-----------|-------|-------|--------|
| **compileSdk** | 34 (Flutter default) | **36** | Requis pour targetSdk 36 |
| **targetSdk** | 34 (Flutter default) | **36** | Exigence Play Store + camera plugin |
| **AGP (Android Gradle Plugin)** | 8.2.0 | **8.6.0** | Flutter recommande ≥8.6.0 |
| **Kotlin** | 1.9.20 | **2.1.0** | Flutter recommande ≥2.1.0 |
| **Java** | VERSION_1_8 | **VERSION_17** | Requis pour AGP 8.x et SDK 36 |
| **Gradle** | 8.7 | **8.7** | Déjà à jour ✅ |
| **Kotlin BOM** | 1.8.0 | **2.1.0** | Aligné avec Kotlin 2.1.0 |
| **desugar_jdk_libs** | 2.0.4 | **2.1.4** | Requis par flutter_local_notifications |

### Fichiers Modifiés

#### 1. `android/settings.gradle`
- **AGP:** 8.2.0 → 8.6.0
- **Kotlin:** 1.9.20 → 2.1.0

#### 2. `android/app/build.gradle`
- **compileSdk:** `flutter.compileSdkVersion` → `36` (hardcoded)
- **targetSdk:** `flutter.targetSdkVersion` → `36` (hardcoded)
- **Java:** `VERSION_1_8` → `VERSION_17`
- **Kotlin jvmTarget:** `"1.8"` → `"17"`
- **Kotlin BOM:** 1.8.0 → 2.1.0
- **desugar_jdk_libs:** 2.0.4 → 2.1.4 (requis par flutter_local_notifications)

#### 3. `android/app/src/main/AndroidManifest.xml`
**Ajouts de permissions pour API 33+ (Android 13+):**
- `POST_NOTIFICATIONS` - Requis pour afficher des notifications sur Android 13+
- `READ_MEDIA_IMAGES` - Pour accès aux photos (scoped storage API 33+)
- `READ_MEDIA_VIDEO` - Pour accès aux vidéos (scoped storage API 33+)
- `READ_EXTERNAL_STORAGE` avec `maxSdkVersion="32"` - Fallback pour Android < 13

#### 4. `flutter_mapbox_navigation/android/build.gradle`
- **compileSdkVersion:** 33 → 36
- **targetSdkVersion:** 33 → 36
- **AGP:** 7.4.2 → 8.6.0
- **Kotlin:** 1.7.10 → 2.1.0
- **Java:** VERSION_1_8 → VERSION_17
- **Token Mapbox:** Rendu optionnel (warning au lieu d'erreur)

#### 5. `android/app/proguard-rules.pro` (NOUVEAU)
- Fichier créé avec règles ProGuard pour Flutter, Firebase, Mapbox, Kotlin coroutines, Hive

### Fichiers Non Modifiés (Contraintes Respectées)
- ✅ Aucun fichier UI/design modifié
- ✅ Aucune couleur/charte graphique modifiée
- ✅ Aucune logique métier modifiée
- ✅ Aucun asset image modifié
- ✅ Configuration keystore préservée

## Problèmes Connus et Solutions

### 1. MAPBOX_DOWNLOADS_TOKEN Manquant

**Problème:** Le plugin `flutter_mapbox_navigation` nécessite un token Mapbox pour télécharger les dépendances.

**Solution:** 
1. Créer un token sur https://account.mapbox.com/access-tokens/
2. Avec les permissions: `DOWNLOADS:READ` et `STYLES:READ`
3. Ajouter dans `android/gradle.properties`:
   ```properties
   MAPBOX_DOWNLOADS_TOKEN=sk.XXXXXXXXXXXXXXX
   ```
4. OU définir comme variable d'environnement:
   ```bash
   export MAPBOX_DOWNLOADS_TOKEN=sk.XXXXXXXXXXXXXXX
   ```

**Note:** Le build affichera un warning si le token n'est pas défini, mais échouera lors du téléchargement des dépendances Mapbox.

### 2. Plugins Flutter - Versions Disponibles

Les plugins suivants ont des versions plus récentes disponibles mais ne sont **pas mis à jour automatiquement** (conformément aux contraintes):

- `firebase_core`: 3.15.1 → 4.2.1 disponible
- `firebase_messaging`: 15.2.9 → 16.0.4 disponible
- `firebase_storage`: 12.4.9 → 13.0.4 disponible
- `cloud_firestore`: 5.6.11 → 6.1.0 disponible
- `permission_handler`: 11.4.0 → 12.0.1 disponible
- `geolocator`: 11.1.0 → 14.0.2 disponible

**Recommandation:** Tester avec les versions actuelles. Si des problèmes de compatibilité apparaissent, mettre à jour progressivement.

## Tests Requis

### Tests Manuels Essentiels

#### 1. Build & Installation
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter build apk --debug` (doit réussir avec token Mapbox)
- [ ] `flutter build apk --release` (doit réussir avec token Mapbox)
- [ ] Installation APK sur device Android 11 (API 30)
- [ ] Installation APK sur device Android 13 (API 33)
- [ ] Installation APK sur device Android 14 (API 34)
- [ ] Installation APK sur device Android 15 (API 35) si disponible

#### 2. Permissions Runtime
- [ ] **Notifications:** Vérifier que la demande de permission `POST_NOTIFICATIONS` apparaît sur Android 13+
- [ ] **Caméra:** Vérifier que l'accès caméra fonctionne
- [ ] **Photos/Vidéos:** Vérifier que `image_picker` et `camera` fonctionnent avec les nouvelles permissions `READ_MEDIA_*`
- [ ] **Localisation:** Vérifier que la localisation fonctionne (fine/coarse)

#### 3. Fonctionnalités Critiques
- [ ] **Authentification Firebase:** Login/logout fonctionne
- [ ] **Notifications Firebase:** Réception de notifications push
- [ ] **Notifications locales:** Affichage de notifications locales
- [ ] **Upload photos:** Upload vers Firebase Storage fonctionne
- [ ] **Navigation Mapbox:** Navigation turn-by-turn fonctionne (si utilisée)
- [ ] **Google Maps:** Affichage de cartes Google Maps fonctionne
- [ ] **Géolocalisation:** Récupération de position fonctionne

#### 4. Background & Foreground Services
- [ ] **Foreground services:** Vérifier que les services foreground fonctionnent (navigation, etc.)
- [ ] **Background tasks:** Vérifier que les tâches en arrière-plan fonctionnent

#### 5. Compatibilité Rétroactive
- [ ] **Android 11 (API 30):** Toutes les fonctionnalités fonctionnent
- [ ] **Android 12 (API 31):** Toutes les fonctionnalités fonctionnent
- [ ] **Android 13 (API 33):** Permissions runtime fonctionnent correctement
- [ ] **Android 14 (API 34):** Toutes les fonctionnalités fonctionnent

### Tests Automatisés (si disponibles)
- [ ] Lancer `flutter test` (tests unitaires/widget)
- [ ] Vérifier qu'aucun test n'est cassé

## Procédure de Rollback

Si des problèmes critiques apparaissent après déploiement:

### Option 1: Rollback Git
```bash
git revert <commit-hash-de-la-migration>
git push
```

### Option 2: Rollback Manuel

1. **Restauration des versions dans `android/settings.gradle`:**
   ```groovy
   id "com.android.application" version "8.2.0" apply false
   id "org.jetbrains.kotlin.android" version "1.9.20" apply false
   ```

2. **Restauration dans `android/app/build.gradle`:**
   ```groovy
   compileSdk = flutter.compileSdkVersion
   targetSdk = flutter.targetSdkVersion
   sourceCompatibility = JavaVersion.VERSION_1_8
   targetCompatibility = JavaVersion.VERSION_1_8
   jvmTarget = JavaVersion.VERSION_1_8
   ```

3. **Suppression des permissions API 33+ dans `AndroidManifest.xml`** (optionnel, peut rester pour compatibilité)

4. **Restauration du plugin `flutter_mapbox_navigation`** (si nécessaire)

5. **Nettoyage et rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

## Points à Surveiller Après Déploiement

### Risques Identifiés

1. **Permissions Runtime (Android 13+)**
   - Les utilisateurs Android 13+ devront accepter la permission `POST_NOTIFICATIONS`
   - Impact: Les notifications peuvent ne pas s'afficher si refusées
   - **Surveillance:** Taux d'acceptation de la permission dans Firebase Analytics

2. **Scoped Storage (Android 13+)**
   - Les plugins `image_picker` et `camera` utilisent maintenant `READ_MEDIA_*` au lieu de `READ_EXTERNAL_STORAGE`
   - Impact: Comportement légèrement différent pour l'accès aux médias
   - **Surveillance:** Erreurs liées à l'accès aux fichiers dans les logs

3. **Compatibilité Plugins**
   - Certains plugins peuvent avoir des comportements inattendus avec SDK 36
   - **Surveillance:** Crashs dans Firebase Crashlytics, logs d'erreurs

4. **Performance**
   - Java 17 peut avoir un impact sur les performances (généralement positif)
   - **Surveillance:** Temps de démarrage, consommation mémoire

### Métriques à Surveiller (1 semaine après déploiement)

- [ ] Taux de crashs (Firebase Crashlytics)
- [ ] Taux d'erreurs liées aux permissions
- [ ] Taux d'erreurs liées au stockage/fichiers
- [ ] Temps de démarrage de l'app
- [ ] Taux d'acceptation de la permission POST_NOTIFICATIONS
- [ ] Feedback utilisateurs sur le Play Store

## Instructions de Build Local

### Prérequis
1. **SDK Android 36** installé dans Android Studio
2. **Java 17** (JDK 17) configuré
3. **MAPBOX_DOWNLOADS_TOKEN** configuré (voir section "Problèmes Connus")

### Build Debug
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Build Release
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Build App Bundle (pour Play Store)
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## Notes de Compatibilité

### Comportements Attendus sur Anciennes Versions Android

- **Android < 13 (API < 33):**
  - `POST_NOTIFICATIONS` n'est pas requise (permission automatique)
  - `READ_EXTERNAL_STORAGE` est utilisée au lieu de `READ_MEDIA_*`
  - Comportement identique à avant la migration

- **Android 13+ (API 33+):**
  - `POST_NOTIFICATIONS` doit être demandée en runtime
  - `READ_MEDIA_IMAGES` et `READ_MEDIA_VIDEO` sont utilisées
  - Scoped storage est appliqué automatiquement

- **Android 15 (API 35):**
  - Toutes les fonctionnalités doivent fonctionner normalement
  - Aucun changement de comportement spécifique attendu

## Support

En cas de problème:
1. Vérifier les logs: `adb logcat | grep -i error`
2. Vérifier Firebase Crashlytics pour les crashs
3. Vérifier que `MAPBOX_DOWNLOADS_TOKEN` est bien configuré
4. Vérifier que Java 17 est bien utilisé: `java -version`

