/// Service pour récupérer les statistiques de livraison pour un livreur
/// Pour le moment, utilise des données statiques pour tester
class DeliveryStatisticsService {
  /// Prix unitaire de livraison (en FC)
  static const double _unitPrice = 2000.0;

  /// Récupère les statistiques de livraison pour un livreur
  Future<Map<String, dynamic>> getDeliveryStatistics(String livreurId) async {
    try {
      // Simuler un délai de chargement
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();

      // Données statiques pour tester
      final dailyDeliveries = [
        {
          'id': '1',
          'orderId': 'CMD-001',
          'clientName': 'Jean Mukamba',
          'clientPhone': '+243819493099',
          'deliveryAddress': 'Avenue Kasa-Vubu, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(hours: 2)),
          'status': 'delivered',
        },
        {
          'id': '2',
          'orderId': 'CMD-002',
          'clientName': 'Marie Kabila',
          'clientPhone': '+243819493100',
          'deliveryAddress': 'Commune de Gombe, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(hours: 5)),
          'status': 'delivered',
        },
        {
          'id': '3',
          'orderId': 'CMD-003',
          'clientName': 'Paul Tshisekedi',
          'clientPhone': '+243819493101',
          'deliveryAddress': 'Quartier Matonge, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(hours: 8)),
          'status': 'delivered',
        },
      ];

      final weeklyDeliveries = [
        ...dailyDeliveries,
        {
          'id': '4',
          'orderId': 'CMD-004',
          'clientName': 'Sophie Lumumba',
          'clientPhone': '+243819493102',
          'deliveryAddress': 'Avenue de la Justice, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 2)),
          'status': 'delivered',
        },
        {
          'id': '5',
          'orderId': 'CMD-005',
          'clientName': 'David Kasa-Vubu',
          'clientPhone': '+243819493103',
          'deliveryAddress': 'Commune de Lingwala, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 3)),
          'status': 'delivered',
        },
        {
          'id': '6',
          'orderId': 'CMD-006',
          'clientName': 'Alice Mobutu',
          'clientPhone': '+243819493104',
          'deliveryAddress': 'Quartier Bandal, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 4)),
          'status': 'delivered',
        },
        {
          'id': '7',
          'orderId': 'CMD-007',
          'clientName': 'Robert Kabila',
          'clientPhone': '+243819493105',
          'deliveryAddress': 'Avenue des Aviateurs, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 5)),
          'status': 'delivered',
        },
      ];

      final monthlyDeliveries = [
        ...weeklyDeliveries,
        {
          'id': '8',
          'orderId': 'CMD-008',
          'clientName': 'Claire Tshisekedi',
          'clientPhone': '+243819493106',
          'deliveryAddress': 'Commune de Kalamu, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 10)),
          'status': 'delivered',
        },
        {
          'id': '9',
          'orderId': 'CMD-009',
          'clientName': 'Pierre Lumumba',
          'clientPhone': '+243819493107',
          'deliveryAddress': 'Quartier Victoire, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 15)),
          'status': 'delivered',
        },
        {
          'id': '10',
          'orderId': 'CMD-010',
          'clientName': 'Lucie Kasa-Vubu',
          'clientPhone': '+243819493108',
          'deliveryAddress': 'Avenue Batetela, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 20)),
          'status': 'delivered',
        },
        {
          'id': '11',
          'orderId': 'CMD-011',
          'clientName': 'Marc Mobutu',
          'clientPhone': '+243819493109',
          'deliveryAddress': 'Commune de Ngaliema, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 25)),
          'status': 'delivered',
        },
      ];

      final semesterDeliveries = [
        ...monthlyDeliveries,
        {
          'id': '12',
          'orderId': 'CMD-012',
          'clientName': 'Nathalie Kabila',
          'clientPhone': '+243819493110',
          'deliveryAddress': 'Quartier Binza, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 60)),
          'status': 'delivered',
        },
        {
          'id': '13',
          'orderId': 'CMD-013',
          'clientName': 'Thomas Tshisekedi',
          'clientPhone': '+243819493111',
          'deliveryAddress': 'Avenue de la Libération, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 90)),
          'status': 'delivered',
        },
        {
          'id': '14',
          'orderId': 'CMD-014',
          'clientName': 'Isabelle Lumumba',
          'clientPhone': '+243819493112',
          'deliveryAddress': 'Commune de Mont-Ngafula, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 120)),
          'status': 'delivered',
        },
      ];

      final yearlyDeliveries = [
        ...semesterDeliveries,
        {
          'id': '15',
          'orderId': 'CMD-015',
          'clientName': 'François Kasa-Vubu',
          'clientPhone': '+243819493113',
          'deliveryAddress': 'Quartier Masina, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 180)),
          'status': 'delivered',
        },
        {
          'id': '16',
          'orderId': 'CMD-016',
          'clientName': 'Catherine Mobutu',
          'clientPhone': '+243819493114',
          'deliveryAddress': 'Avenue Kasa-Vubu, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 240)),
          'status': 'delivered',
        },
        {
          'id': '17',
          'orderId': 'CMD-017',
          'clientName': 'Henri Kabila',
          'clientPhone': '+243819493115',
          'deliveryAddress': 'Commune de Selembao, Kinshasa',
          'unitPrice': _unitPrice,
          'total': _unitPrice,
          'date': now.subtract(const Duration(days: 300)),
          'status': 'delivered',
        },
      ];

      // Calculer les totaux
      final dailyTotal = dailyDeliveries.fold<double>(0.0, (sum, delivery) => sum + (delivery['total'] as double));
      final weeklyTotal = weeklyDeliveries.fold<double>(0.0, (sum, delivery) => sum + (delivery['total'] as double));
      final monthlyTotal = monthlyDeliveries.fold<double>(0.0, (sum, delivery) => sum + (delivery['total'] as double));
      final semesterTotal = semesterDeliveries.fold<double>(0.0, (sum, delivery) => sum + (delivery['total'] as double));
      final yearlyTotal = yearlyDeliveries.fold<double>(0.0, (sum, delivery) => sum + (delivery['total'] as double));

      return {
        'success': true,
        'unitPrice': _unitPrice,
        'daily': {
          'total': dailyTotal,
          'count': dailyDeliveries.length,
          'deliveries': dailyDeliveries,
        },
        'weekly': {
          'total': weeklyTotal,
          'count': weeklyDeliveries.length,
          'deliveries': weeklyDeliveries,
        },
        'monthly': {
          'total': monthlyTotal,
          'count': monthlyDeliveries.length,
          'deliveries': monthlyDeliveries,
        },
        'semester': {
          'total': semesterTotal,
          'count': semesterDeliveries.length,
          'deliveries': semesterDeliveries,
        },
        'yearly': {
          'total': yearlyTotal,
          'count': yearlyDeliveries.length,
          'deliveries': yearlyDeliveries,
        },
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques de livraison: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

