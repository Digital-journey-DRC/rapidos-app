# Optimisation de la Taille de l'APK

## 📊 Réductions Attendues

Avec les optimisations appliquées, la taille de l'APK devrait passer de **~145 MB** à environ **40-60 MB par APK** (selon l'architecture).

### Optimisations Appliquées

1. **Split APKs par ABI** ✅
   - Création d'APKs séparés pour chaque architecture
   - Chaque APK contient seulement les bibliothèques natives nécessaires
   - Réduction de ~50-60% de la taille

2. **Filtrage des Architectures** ✅
   - Suppression de `x86` et `x86_64` (rarement utilisés sur mobile)
   - Conservation de `armeabi-v7a` (32-bit) et `arm64-v8a` (64-bit)
   - Réduction de ~25-30% de la taille

3. **Optimisation des Ressources** ✅
   - Exclusion des fichiers META-INF inutiles
   - Minification et shrinkResources activés
   - Réduction de ~5-10% de la taille

4. **Configuration Release Optimisée** ✅
   - Désactivation du debug
   - ProGuard/R8 activé avec optimisations

## 🚀 Comment Construire

### Option 1: APKs Split (Recommandé pour distribution directe)

```bash
flutter build apk --release --split-per-abi
```

Cela génère 2 APKs :
- `app-armeabi-v7a-release.apk` (~40-50 MB)
- `app-arm64-v8a-release.apk` (~45-60 MB)

**Avantage:** Chaque utilisateur installe seulement l'APK pour son architecture.

### Option 2: App Bundle (Recommandé pour Play Store)

```bash
flutter build appbundle --release
```

Cela génère un fichier `.aab` que le Play Store utilise pour créer automatiquement des APKs optimisés par architecture.

**Avantage:** Le Play Store gère automatiquement la distribution des APKs par architecture.

### Option 3: APK Universel (Non recommandé - plus volumineux)

Si vous avez besoin d'un APK universel (pour tester ou distribution hors Play Store), modifiez temporairement `build.gradle` :

```gradle
splits {
    abi {
        enable false  // Désactiver le split
    }
}
```

Puis construisez :
```bash
flutter build apk --release
```

## 📱 Distribution des APKs Split

### Pour le Play Store
- **Utilisez App Bundle (.aab)** - Le Play Store gère automatiquement la distribution
- Ne téléversez pas les APKs split manuellement

### Pour Distribution Directe (Hors Play Store)
- Fournissez les 2 APKs (`armeabi-v7a` et `arm64-v8a`)
- Les utilisateurs doivent installer celui correspondant à leur appareil
- La plupart des appareils modernes utilisent `arm64-v8a`

### Comment Identifier l'Architecture d'un Appareil

Les utilisateurs peuvent vérifier leur architecture avec une app comme "Device Info HW" ou via ADB :
```bash
adb shell getprop ro.product.cpu.abi
```

## 🔍 Vérification de la Taille

Après le build, vérifiez la taille des APKs générés :

```bash
ls -lh build/app/outputs/flutter-apk/*.apk
```

## 📈 Optimisations Supplémentaires Possibles

Si vous avez encore besoin de réduire la taille :

1. **Optimiser les Images**
   - Compresser les images dans `assets/images/`
   - Utiliser WebP au lieu de PNG quand possible
   - Réduire la résolution des images non critiques

2. **Analyser les Dépendances**
   ```bash
   flutter pub deps --style=tree | grep -E "(google_maps|mapbox|firebase)"
   ```
   - Vérifier si toutes les dépendances sont nécessaires
   - Certaines dépendances (comme Mapbox) peuvent être volumineuses

3. **Utiliser ProGuard Plus Agressif**
   - Ajouter des règles ProGuard personnalisées dans `proguard-rules.pro`
   - Exclure les classes inutilisées

4. **Considérer le Lazy Loading**
   - Charger certaines fonctionnalités à la demande
   - Utiliser des modules dynamiques (si nécessaire)

## ⚠️ Notes Importantes

- Les APKs split ne peuvent pas être installés sur des émulateurs x86/x86_64
- Pour les tests, utilisez un APK universel ou un émulateur ARM
- Le Play Store recommande fortement l'utilisation d'App Bundle (.aab) plutôt que d'APKs

## 📝 Résumé des Changements

Fichier modifié : `android/app/build.gradle`

- ✅ Ajout de `splits.abi` pour créer des APKs par architecture
- ✅ Filtrage des ABI (seulement `armeabi-v7a` et `arm64-v8a`)
- ✅ Exclusion des fichiers META-INF inutiles
- ✅ Optimisations supplémentaires dans `buildTypes.release`

