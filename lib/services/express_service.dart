import 'package:cloud_firestore/cloud_firestore.dart';

class ExpressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un nouveau client
  Future<String> createClient(Map<String, dynamic> clientData) async {
    try {
      print('📝 Création de client avec les données: $clientData');
      print('📝 ID vendeur (createdBy): ${clientData['createdBy']}');
      print('📝 ID vendeur (vendeurId): ${clientData['vendeurId']}');
      
      final dataToSave = {
        ...clientData,
        'vendeurId': clientData['createdBy'], // S'assurer que vendeurId est défini
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('📝 Données finales à sauvegarder: $dataToSave');
      
      final docRef = await _firestore.collection('clients').add(dataToSave);
      
      print('✅ Client créé avec succès, ID: ${docRef.id}');
      print('✅ Données sauvegardées: $dataToSave');
      
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création du client: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  // Récupérer tous les clients
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      print('🔍 Récupération de tous les clients');
      
      final querySnapshot = await _firestore
          .collection('clients')
          .get();
      
      print('📊 Nombre total de clients: ${querySnapshot.docs.length}');
      
      final clients = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('👤 Client: ${data['firstName']} ${data['lastName']} - vendeurId: ${data['vendeurId']} - createdBy: ${data['createdBy']}');
        return data;
      }).toList();
      
      // Vérifier les clients sans vendeurId
      final clientsWithoutVendeurId = clients.where((client) => client['vendeurId'] == null).toList();
      if (clientsWithoutVendeurId.isNotEmpty) {
        print('⚠️ ATTENTION: ${clientsWithoutVendeurId.length} clients sans vendeurId:');
        for (final client in clientsWithoutVendeurId) {
          print('   - ${client['firstName']} ${client['lastName']} (ID: ${client['id']})');
        }
      }
      
      // Trier côté client
      clients.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt); // Plus récent en premier
      });
      
      print('✅ ${clients.length} clients trouvés au total');
      return clients;
    } catch (e) {
      print('❌ Erreur lors de la récupération des clients: $e');
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  // Récupérer les clients d'un vendeur spécifique
  Future<List<Map<String, dynamic>>> getClientsByVendeur(String vendeurId) async {
    try {
      print('🔍 Recherche des clients pour le vendeur: $vendeurId');
      
      // Requête simple sans orderBy pour éviter les problèmes d'index
      final querySnapshot = await _firestore
          .collection('clients')
          .where('vendeurId', isEqualTo: vendeurId)
          .get();
      
      print('📊 Nombre de documents trouvés: ${querySnapshot.docs.length}');
      
      final clients = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('👤 Client trouvé: ${data['firstName']} ${data['lastName']} - vendeurId: ${data['vendeurId']}');
        return data;
      }).toList();
      
      // Trier côté client pour éviter les problèmes d'index
      clients.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt); // Plus récent en premier
      });
      
      print('✅ ${clients.length} clients trouvés pour le vendeur $vendeurId');
      
      // Vérifier que tous les clients ont le bon vendeurId
      for (final client in clients) {
        if (client['vendeurId'] != vendeurId) {
          print('⚠️ ATTENTION: Client ${client['firstName']} ${client['lastName']} a vendeurId: ${client['vendeurId']} au lieu de $vendeurId');
        }
      }
      
      return clients;
    } catch (e) {
      print('❌ Erreur lors de la récupération des clients: $e');
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  // Créer une commande express
  Future<String> createExpressOrder(Map<String, dynamic> orderData) async {
    try {
      print('📦 Création de commande express avec les données: $orderData');
      
      final docRef = await _firestore.collection('express_orders').add({
        ...orderData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Commande express créée avec l\'ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création de la commande: $e');
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  // Récupérer les commandes express
  Future<List<Map<String, dynamic>>> getExpressOrders() async {
    try {
      print('🔍 Récupération des commandes express');
      
      final querySnapshot = await _firestore
          .collection('express_orders')
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Trier côté client
      orders.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt); // Plus récent en premier
      });
      
      print('✅ ${orders.length} commandes express trouvées');
      return orders;
    } catch (e) {
      print('❌ Erreur lors de la récupération des commandes: $e');
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  // Récupérer les commandes express par vendeur
  Future<List<Map<String, dynamic>>> getExpressOrdersByVendeur(String vendeurId) async {
    try {
      print('🔍 Récupération des commandes express pour le vendeur: $vendeurId');
      
      final querySnapshot = await _firestore
          .collection('express_orders')
          .where('createdBy', isEqualTo: vendeurId)
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Trier côté client
      orders.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt); // Plus récent en premier
      });
      
      print('✅ ${orders.length} commandes express trouvées pour le vendeur $vendeurId');
      return orders;
    } catch (e) {
      print('❌ Erreur lors de la récupération des commandes: $e');
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  // Mettre à jour le statut d'une commande
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('express_orders')
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Corriger les clients existants sans vendeurId
  Future<void> fixClientsWithoutVendeurId() async {
    try {
      print('🔧 Correction des clients sans vendeurId...');
      
      final querySnapshot = await _firestore
          .collection('clients')
          .where('vendeurId', isNull: true)
          .get();
      
      print('📊 ${querySnapshot.docs.length} clients sans vendeurId trouvés');
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final createdBy = data['createdBy'];
        
        if (createdBy != null) {
          await doc.reference.update({
            'vendeurId': createdBy,
          });
          print('✅ Client ${data['firstName']} ${data['lastName']} corrigé avec vendeurId: $createdBy');
        } else {
          print('⚠️ Client ${data['firstName']} ${data['lastName']} n\'a pas de createdBy');
        }
      }
      
      print('✅ Correction terminée');
    } catch (e) {
      print('❌ Erreur lors de la correction: $e');
    }
  }
} 