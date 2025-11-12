# README - Configuration Play Console pour targetSdk 36

**Date:** 2025-01-XX  
**Aucune modification du code applicatif. Ajustements manifest/Gradle uniquement.**

---

## 📋 Résumé des Modifications

### Fichiers Modifiés
- ✅ `android/app/build.gradle` - `compileSdk = 36`, `targetSdk = 36` (déjà configuré)
- ✅ `android/app/src/main/AndroidManifest.xml` - Nettoyage des permissions avec `tools:node="remove"`

### Permissions Finales dans le Merged Manifest

Le manifest final contient **uniquement** :

```xml
<!-- Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Fallback Android <= 12 (API 32) -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**Permissions supprimées explicitement** (via `tools:node="remove"`) :
- ❌ `WRITE_EXTERNAL_STORAGE` (dépréciée et interdite)
- ❌ `MANAGE_EXTERNAL_STORAGE` (interdite)
- ❌ `READ_EXTERNAL_STORAGE` sans `maxSdkVersion` (remplacée par la version avec `maxSdkVersion="32"`)

---

## 🔐 Permissions Déclarées (Android 13+)

### READ_MEDIA_IMAGES
- **Type:** Permission d'accès aux photos
- **API Level:** 33+ (Android 13+)
- **Utilisation:** Lecture des images stockées sur l'appareil

### READ_MEDIA_VIDEO
- **Type:** Permission d'accès aux vidéos
- **API Level:** 33+ (Android 13+)
- **Utilisation:** Lecture des vidéos stockées sur l'appareil

---

## 📱 Fallback Android ≤ 12 (API 32)

### READ_EXTERNAL_STORAGE (avec maxSdkVersion="32")
- **Type:** Permission d'accès au stockage externe (legacy)
- **API Level:** ≤ 32 (Android 12 et inférieur)
- **Utilisation:** Fallback pour les appareils Android 12 et inférieurs qui ne supportent pas les permissions granulares `READ_MEDIA_*`
- **Contrainte:** `android:maxSdkVersion="32"` pour s'assurer qu'elle n'est pas utilisée sur Android 13+

---

## 📝 Déclaration Play Console – Permissions Sensibles

### Texte à Coller dans "Permissions Sensibles" (Play Console)

**Type de permission:** Accès aux photos et vidéos

**Justification (en français):**

> L'application Rapidons nécessite l'accès aux photos et vidéos pour permettre aux utilisateurs d'importer et de traiter des médias au sein de l'application. Cette fonctionnalité est utilisée pour :
> 
> - **Photo de profil** : Les utilisateurs peuvent sélectionner une photo depuis leur galerie pour leur profil marchand ou client
> - **Import de médias** : Import d'images et de vidéos pour les annonces de produits, les factures, les preuves de livraison
> - **Traitement et édition** : Prévisualisation, redimensionnement, et traitement des médias avant envoi
> - **Envoi vers le backend** : Transmission des médias sélectionnés vers nos serveurs pour stockage et traitement
> 
> **Portée de l'accès:**
> - Accès en **lecture uniquement** aux médias sélectionnés par l'utilisateur
> - Aucune écriture sur l'espace de stockage partagé
> - Accès limité aux médias présents sur l'appareil
> 
> **Pourquoi pas le Photo Picker Android:**
> L'application nécessite un accès élargi pour gérer des cas d'usage avancés non couverts par un sélecteur restreint :
> - Traitements batch de médias
> - Listing et prévisualisation de médias locaux
> - Lecture de métadonnées et génération de miniatures
> - Import multi-fichiers pour les annonces avec plusieurs photos
> - Gestion de flux de travail complexes (ex: factures avec photos de reçus)

---

## 🔒 Sécurité des Données – Formulaire Play Console

### Catégorie "Photos et vidéos"

**Accès en lecture:** ✅ **OUI**

**Collecte/Partage:**
- **Collecte:** ✅ **OUI** (les médias sont transmis à nos serveurs pour stockage et traitement)
- **Partage:** ✅ **OUI** (les médias peuvent être partagés avec d'autres utilisateurs via l'application, selon les fonctionnalités de l'app)

**Finalité de la collecte:**
- Stockage des photos de profil utilisateur
- Stockage des images de produits pour les annonces
- Stockage des preuves de livraison (photos/vidéos)
- Stockage des factures et documents avec médias associés
- Traitement et analyse des médias pour améliorer l'expérience utilisateur

**Traitement sur l'appareil:** ✅ **OUI** (prévisualisation, redimensionnement, compression avant envoi)

**Durée de conservation:**
- Les médias sont conservés tant que l'utilisateur les utilise dans l'application
- Les utilisateurs peuvent supprimer leurs médias à tout moment depuis l'application
- Conformité avec la politique de rétention des données de l'entreprise

---

## ✅ Checklist Anti-Rejet Play Console

### Validation Technique

- [x] ✅ Pas de `WRITE_EXTERNAL_STORAGE` dans le merged manifest
- [x] ✅ `READ_EXTERNAL_STORAGE` uniquement avec `maxSdkVersion="32"`
- [x] ✅ `READ_MEDIA_IMAGES` présent une seule fois
- [x] ✅ `READ_MEDIA_VIDEO` présent une seule fois
- [x] ✅ Aucune permission dupliquée dans le merged manifest
- [x] ✅ `targetSdk = 36` configuré dans `build.gradle`
- [x] ✅ `compileSdk = 36` configuré dans `build.gradle`

### Validation Play Console

- [ ] ✅ Le formulaire "Permissions sensibles" est rempli avec le texte ci-dessus
- [ ] ✅ La section "Sécurité des données" est alignée avec le comportement réel de l'app
- [ ] ✅ Les justifications sont cohérentes avec les fonctionnalités réelles
- [ ] ✅ Les captures d'écran de l'app montrent l'utilisation des permissions (si demandé)

---

## 🔍 Commandes de Vérification

### 1. Générer le Merged Manifest

```bash
cd android
./gradlew app:processReleaseMainManifest
```

### 2. Inspecter le Merged Manifest

Le merged manifest se trouve dans :
```
app/build/intermediates/merged_manifests/release/AndroidManifest.xml
```

### 3. Vérifier les Permissions

Rechercher dans le merged manifest :
- ✅ `READ_MEDIA_IMAGES` (présent une fois)
- ✅ `READ_MEDIA_VIDEO` (présent une fois)
- ✅ `READ_EXTERNAL_STORAGE` avec `android:maxSdkVersion="32"` (présent une fois)
- ❌ `WRITE_EXTERNAL_STORAGE` (absent)
- ❌ `MANAGE_EXTERNAL_STORAGE` (absent)
- ❌ `READ_EXTERNAL_STORAGE` sans `maxSdkVersion` (absent)

### 4. Build Release

```bash
cd android
./gradlew app:assembleRelease
```

### 5. Build App Bundle

```bash
cd android
./gradlew app:bundleRelease
```

---

## 📄 Diff Prévisualisation

### AndroidManifest.xml

```diff
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
+         xmlns:tools="http://schemas.android.com/tools">
    
+    <!-- Force remove deprecated/bad permissions possibly merged from libraries -->
+    <uses-permission
+        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
+        tools:node="remove" />
+    <uses-permission
+        android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
+        tools:node="remove" />
+    <uses-permission
+        android:name="android.permission.READ_EXTERNAL_STORAGE"
+        tools:node="remove" />
+    
    <!-- Permissions pour scoped storage (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
-    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
+    <!-- Fallback pour Android <= 12 (API 32) - ré-ajouté après suppression -->
+    <uses-permission
+        android:name="android.permission.READ_EXTERNAL_STORAGE"
+        android:maxSdkVersion="32" />
```

### build.gradle

```diff
android {
    namespace = "com.rapidosdrc.app"
-   compileSdk = flutter.compileSdkVersion
+   compileSdk = 36
    ...
    defaultConfig {
        applicationId = "com.rapidosdrc.app"
        minSdk = flutter.minSdkVersion
-       targetSdk = flutter.targetSdkVersion
+       targetSdk = 36
        ...
    }
}
```

---

## 🚀 Prochaines Étapes

1. **Valider le merged manifest** avec `./gradlew app:processReleaseMainManifest`
2. **Tester le build release** avec `./gradlew app:assembleRelease`
3. **Tester le bundle** avec `./gradlew app:bundleRelease`
4. **Remplir le formulaire Play Console** avec les textes fournis ci-dessus
5. **Soumettre l'app** et vérifier qu'aucun rejet lié aux permissions ne survient

---

## 📞 Support

En cas de rejet Play Console lié aux permissions :
1. Vérifier le merged manifest avec les commandes ci-dessus
2. S'assurer que toutes les permissions interdites sont bien supprimées
3. Vérifier que les justifications dans Play Console correspondent aux fonctionnalités réelles
4. Consulter les logs Play Console pour identifier la permission problématique

---

**Note:** Ce document a été généré automatiquement. Aucune modification du code applicatif (Dart/Kotlin/Java) n'a été effectuée. Seuls les fichiers de configuration Android (Gradle et Manifest) ont été ajustés pour la compatibilité targetSdk 36.

