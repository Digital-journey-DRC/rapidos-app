# Guide de Configuration Firebase - Collection Version

## 1. Accéder à Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet Rapidos
3. Dans le menu de gauche, cliquez sur **Firestore Database**

## 2. Créer la Collection Version

### Étape 1 : Créer la Collection
1. Cliquez sur **Créer une collection**
2. Nom de la collection : `version`
3. Cliquez sur **Suivant**

### Étape 2 : Créer le Document
1. ID du document : `latest`
2. Cliquez sur **Suivant**

### Étape 3 : Ajouter les Champs
Ajoutez les champs suivants :

| Nom du champ | Type | Valeur | Description |
|--------------|------|--------|-------------|
| `ios` | number | `3` | Version minimale pour iOS |
| `android` | number | `4` | Version minimale pour Android |
| `description` | string | `Améliorations et corrections de bugs` | Description de la mise à jour |

### Étape 4 : Sauvegarder
1. Cliquez sur **Terminé**

## 3. Structure Finale

Votre collection devrait ressembler à ceci :

```
version (collection)
└── latest (document)
    ├── ios: 3
    ├── android: 4
    └── description: "Améliorations et corrections de bugs"
```

## 4. Test de Configuration

### Vérifier la Version Actuelle
Votre version actuelle dans `pubspec.yaml` :
```yaml
version: 1.0.8+8  # Le build number est 8
```

### Logique de Test
- **Version actuelle** : Build number 8
- **Version Firebase** : iOS 3, Android 4
- **Résultat** : 8 > 3 et 8 > 4 → Pas de modal de mise à jour

### Pour Tester le Modal
1. Changez les valeurs dans Firebase :
   - `ios: 10`
   - `android: 10`
2. Relancez l'app
3. Le modal devrait s'afficher car 8 < 10

## 5. Gestion des Versions

### Workflow de Mise à Jour
1. **Développement** : Version 1.0.8+8
2. **Firebase** : android: 9, ios: 9
3. **Utilisateur** : Version 1.0.8+8 < 9 → Modal de mise à jour
4. **Store** : Version 1.0.8+9 disponible
5. **Utilisateur** : Met à jour → Version 1.0.8+9 ≥ 9 → Pas de modal

### Exemple de Configuration
```json
{
  "ios": 9,
  "android": 9,
  "description": "Nouvelle version avec corrections de bugs et améliorations de performance"
}
```

## 6. Permissions Firestore

### Règles de Sécurité
Assurez-vous que vos règles Firestore permettent la lecture :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /version/{document} {
      allow read: if true;  // Lecture publique pour la collection version
    }
  }
}
```

## 7. Dépannage

### Erreurs Courantes

1. **Collection non trouvée**
   - Vérifiez que la collection `version` existe
   - Vérifiez que le document `latest` existe

2. **Champs manquants**
   - Vérifiez que tous les champs sont présents
   - Vérifiez les types de données (number pour ios/android)

3. **Permissions**
   - Vérifiez les règles de sécurité Firestore
   - Assurez-vous que l'app peut lire la collection

### Logs de Débogage
Les logs apparaîtront dans la console :
- ✅ `Document version trouvé dans Firebase`
- ❌ `Document version non trouvé dans Firebase`
- 📱 `Version actuelle: X, Version minimale: Y`

## 8. Test Manuel

### Écrans de Test Disponibles

1. **Écran de Test Firebase** : `/test-firebase`
   - Affiche les informations de version actuelles
   - Teste la connexion Firebase
   - Compare les versions

2. **Écran d'Administration** : `/admin-version`
   - Gère les versions depuis l'application
   - Force les mises à jour
   - Crée des versions de test

### Accès aux Écrans de Test

```dart
// Dans n'importe quel écran
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/test-firebase'),
  child: Text('Test Firebase'),
)

ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/admin-version'),
  child: Text('Admin Versions'),
)
```

### Test Manuel Simple

```dart
// Dans n'importe quel écran
ElevatedButton(
  onPressed: () async {
    await VersionService.checkForUpdate(context);
  },
  child: Text('Test Version Check'),
)
```

## 9. Configuration Avancée

### URLs des Stores
Modifiez les URLs dans `lib/services/store_service.dart` :

```dart
static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rapidos.app';
static const String _appStoreUrl = 'https://apps.apple.com/app/rapidos/id123456789';
```

### Personnalisation du Modal
Modifiez les couleurs et textes dans `lib/widgets/update_modal.dart`
