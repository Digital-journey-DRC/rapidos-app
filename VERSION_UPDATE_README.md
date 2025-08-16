# Système de Vérification de Version - Rapidos App

## Configuration Firebase

### 1. Structure de la Collection Firebase

Créez une collection `version` dans Firestore avec un document `latest` contenant :

```json
{
  "ios": 3,
  "android": 4,
  "description": "Améliorations et corrections de bugs"
}
```

### 2. Champs de la Collection

- **ios**: Numéro de build minimum requis pour iOS
- **android**: Numéro de build minimum requis pour Android  
- **description**: Description des changements (optionnel)

### 3. Configuration des URLs des Stores

Modifiez les URLs dans `lib/services/store_service.dart` :

```dart
// Remplacez par vos vraies URLs
static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rapidos.app';
static const String _appStoreUrl = 'https://apps.apple.com/app/rapidos/id123456789';
```

## Fonctionnement

### Vérification Automatique

Le système vérifie automatiquement la version au démarrage de l'application :

1. Récupère la version actuelle de l'app
2. Compare avec la version minimale dans Firebase
3. Affiche un modal de mise à jour forcée si nécessaire

### Modal de Mise à Jour

- **Design moderne** avec gradient et animations
- **Impossible à fermer** (mise à jour obligatoire)
- **Bouton direct** vers le store approprié
- **Adaptation automatique** selon la plateforme (iOS/Android)

## Utilisation

### Intégration Automatique

La vérification de version est maintenant intégrée dans :
- **LoginScreen** : Vérification au démarrage de l'écran de connexion
- **MainScreen** : Vérification après l'initialisation de l'écran principal

### Vérification Manuelle

```dart
// Pour vérifier manuellement
await VersionService.checkForUpdate(context);
```

### Utilisation du Wrapper

```dart
// Pour wrapper un écran avec vérification automatique
VersionCheckWrapper(
  child: YourScreen(),
)
```

### Affichage Manuel du Modal

```dart
// Pour afficher le modal manuellement
UpdateModalHelper.showUpdateModal(
  context,
  description: "Description de la mise à jour",
);
```

## Gestion des Versions

### Version Actuelle

La version actuelle est définie dans `pubspec.yaml` :

```yaml
version: 1.0.8+8  # 1.0.8 = version, 8 = build number
```

### Mise à Jour de la Version

1. Incrémentez le build number dans `pubspec.yaml`
2. Mettez à jour les valeurs dans Firebase
3. Publiez la nouvelle version sur les stores

## Exemple de Workflow

1. **Développement** : Version 1.0.8+8
2. **Firebase** : android: 9, ios: 9
3. **Utilisateur** : Version 1.0.8+8 < 9 → Modal de mise à jour
4. **Store** : Version 1.0.8+9 disponible
5. **Utilisateur** : Met à jour → Version 1.0.8+9 ≥ 9 → Pas de modal

## Personnalisation

### Couleurs du Modal

Modifiez les couleurs dans `lib/widgets/update_modal.dart` :

```dart
gradient: const LinearGradient(
  colors: [
    Color(0xFF667eea),  // Couleur 1
    Color(0xFF764ba2),  // Couleur 2
  ],
),
```

### Texte du Modal

Modifiez les textes dans `lib/widgets/update_modal.dart` :

```dart
const Text(
  'Mise à jour disponible',  // Titre
  // ...
),
```

## Dépannage

### Erreurs Courantes

1. **Document Firebase manquant** : Vérifiez que le document `latest` existe
2. **URLs des stores incorrectes** : Mettez à jour les URLs dans `StoreService`
3. **Permissions réseau** : Vérifiez la connectivité internet

### Logs de Débogage

Les logs sont affichés dans la console :
- ✅ Vérification réussie
- ❌ Erreur de vérification
- 📱 Version actuelle vs minimale
