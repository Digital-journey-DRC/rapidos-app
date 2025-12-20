import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajouter une note et un commentaire pour un produit
  Future<void> addReview({
    required int productId,
    required String userId,
    required String userName,
    required int rating, // 1 à 4 étoiles
    required String comment,
  }) async {
    try {
      // Limiter la note à 4 étoiles max
      final finalRating = rating > 4 ? 4 : (rating < 1 ? 1 : rating);

      await _firestore.collection('product_reviews').add({
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': finalRating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la note moyenne du produit
      await _updateProductAverageRating(productId);
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de l\'avis: $e');
      throw Exception('Erreur lors de l\'ajout de l\'avis: $e');
    }
  }

  // Récupérer tous les avis d'un produit
  Stream<List<Map<String, dynamic>>> getProductReviews(int productId) {
    return _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      try {
        final reviews = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return {
              'id': doc.id,
              'productId': data['productId'],
              'userId': data['userId'],
              'userName': data['userName'] ?? 'Utilisateur',
              'rating': data['rating'] ?? 0,
              'comment': data['comment'] ?? '',
              'createdAt': data['createdAt'],
            };
          } catch (e) {
            print('❌ Erreur lors du parsing du document ${doc.id}: $e');
            return null;
          }
        }).where((review) => review != null).cast<Map<String, dynamic>>().toList();

        // Trier par date (plus récent en premier)
        reviews.sort((a, b) {
          final aDate = a['createdAt'] as Timestamp?;
          final bDate = b['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        return reviews;
      } catch (e) {
        print('❌ Erreur lors du traitement des avis: $e');
        return <Map<String, dynamic>>[];
      }
    }).handleError((error, stackTrace) {
      print('❌ Erreur dans le stream getProductReviews: $error');
      print('❌ Stack trace: $stackTrace');
      return <Map<String, dynamic>>[];
    });
  }

  // Calculer la note moyenne d'un produit
  Future<double> getAverageRating(int productId) async {
    try {
      final snapshot = await _firestore
          .collection('product_reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      int totalRating = 0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0) as int;
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur lors du calcul de la note moyenne: $e');
      return 0.0;
    }
  }

  // Mettre à jour la note moyenne du produit
  Future<void> _updateProductAverageRating(int productId) async {
    try {
      final averageRating = await getAverageRating(productId);
      // Optionnel: stocker la note moyenne dans une collection séparée pour un accès plus rapide
      await _firestore.collection('product_ratings').doc(productId.toString()).set({
        'productId': productId,
        'averageRating': averageRating,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la note moyenne: $e');
    }
  }

  // Vérifier si l'utilisateur a déjà noté ce produit
  Future<bool> hasUserReviewed(int productId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('product_reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'avis: $e');
      return false;
    }
  }

  // Récupérer la note moyenne d'un produit (depuis le cache si disponible)
  Future<double> getCachedAverageRating(int productId) async {
    try {
      final doc = await _firestore
          .collection('product_ratings')
          .doc(productId.toString())
          .get();

      if (doc.exists) {
        return (doc.data()?['averageRating'] ?? 0.0).toDouble();
      }

      // Si pas de cache, calculer et mettre en cache
      return await getAverageRating(productId);
    } catch (e) {
      print('❌ Erreur lors de la récupération de la note moyenne: $e');
      return 0.0;
    }
  }

  // Modifier un commentaire
  Future<void> updateReview({
    required String reviewId,
    required int productId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Limiter la note à 4 étoiles max
      final finalRating = rating > 4 ? 4 : (rating < 1 ? 1 : rating);

      await _firestore.collection('product_reviews').doc(reviewId).update({
        'rating': finalRating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la note moyenne du produit
      await _updateProductAverageRating(productId);
    } catch (e) {
      print('❌ Erreur lors de la modification de l\'avis: $e');
      throw Exception('Erreur lors de la modification de l\'avis: $e');
    }
  }

  // Supprimer un commentaire
  Future<void> deleteReview({
    required String reviewId,
    required int productId,
  }) async {
    try {
      await _firestore.collection('product_reviews').doc(reviewId).delete();

      // Mettre à jour la note moyenne du produit
      await _updateProductAverageRating(productId);
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'avis: $e');
      throw Exception('Erreur lors de la suppression de l\'avis: $e');
    }
  }
}

