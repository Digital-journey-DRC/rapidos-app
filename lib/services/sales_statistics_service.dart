class SalesStatisticsService {

  /// Récupère les statistiques de vente pour un marchand
  /// Pour le moment, utilise des données statiques pour tester
  Future<Map<String, dynamic>> getSalesStatistics(String merchantId) async {
    try {
      // Simuler un délai de chargement
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();
      
      // Données statiques pour tester
      final dailySales = [
        {
          'id': '1',
          'orderId': 'CMD-001',
          'clientName': 'Jean Mukamba',
          'total': 45000.0,
          'date': now.subtract(const Duration(hours: 2)),
          'items': [
            {'name': 'Téléphone Samsung', 'quantity': 1, 'price': 25000.0},
            {'name': 'Écouteurs Bluetooth', 'quantity': 2, 'price': 10000.0},
          ],
        },
        {
          'id': '2',
          'orderId': 'CMD-002',
          'clientName': 'Marie Kabila',
          'total': 32000.0,
          'date': now.subtract(const Duration(hours: 5)),
          'items': [
            {'name': 'Sac à dos', 'quantity': 1, 'price': 15000.0},
            {'name': 'Chaussures de sport', 'quantity': 1, 'price': 17000.0},
          ],
        },
        {
          'id': '3',
          'orderId': 'CMD-003',
          'clientName': 'Paul Tshisekedi',
          'total': 28000.0,
          'date': now.subtract(const Duration(hours: 8)),
          'items': [
            {'name': 'Montre intelligente', 'quantity': 1, 'price': 28000.0},
          ],
        },
      ];

      final weeklySales = [
        ...dailySales,
        {
          'id': '4',
          'orderId': 'CMD-004',
          'clientName': 'Sophie Lumumba',
          'total': 55000.0,
          'date': now.subtract(const Duration(days: 2)),
          'items': [
            {'name': 'Ordinateur portable', 'quantity': 1, 'price': 40000.0},
            {'name': 'Souris sans fil', 'quantity': 1, 'price': 15000.0},
          ],
        },
        {
          'id': '5',
          'orderId': 'CMD-005',
          'clientName': 'David Kasa-Vubu',
          'total': 38000.0,
          'date': now.subtract(const Duration(days: 3)),
          'items': [
            {'name': 'Tablette Android', 'quantity': 1, 'price': 38000.0},
          ],
        },
        {
          'id': '6',
          'orderId': 'CMD-006',
          'clientName': 'Alice Mobutu',
          'total': 42000.0,
          'date': now.subtract(const Duration(days: 4)),
          'items': [
            {'name': 'Casque audio', 'quantity': 1, 'price': 25000.0},
            {'name': 'Haut-parleur Bluetooth', 'quantity': 1, 'price': 17000.0},
          ],
        },
        {
          'id': '7',
          'orderId': 'CMD-007',
          'clientName': 'Robert Kabila',
          'total': 29000.0,
          'date': now.subtract(const Duration(days: 5)),
          'items': [
            {'name': 'Power Bank 20000mAh', 'quantity': 2, 'price': 14500.0},
          ],
        },
      ];

      final monthlySales = [
        ...weeklySales,
        {
          'id': '8',
          'orderId': 'CMD-008',
          'clientName': 'Claire Tshisekedi',
          'total': 67000.0,
          'date': now.subtract(const Duration(days: 8)),
          'items': [
            {'name': 'Smartphone iPhone', 'quantity': 1, 'price': 50000.0},
            {'name': 'Coque de protection', 'quantity': 1, 'price': 5000.0},
            {'name': 'Film protecteur', 'quantity': 2, 'price': 6000.0},
          ],
        },
        {
          'id': '9',
          'orderId': 'CMD-009',
          'clientName': 'Marc Lumumba',
          'total': 51000.0,
          'date': now.subtract(const Duration(days: 10)),
          'items': [
            {'name': 'Laptop Dell', 'quantity': 1, 'price': 45000.0},
            {'name': 'Clavier USB', 'quantity': 1, 'price': 6000.0},
          ],
        },
        {
          'id': '10',
          'orderId': 'CMD-010',
          'clientName': 'Julie Kasa-Vubu',
          'total': 44000.0,
          'date': now.subtract(const Duration(days: 12)),
          'items': [
            {'name': 'Enceinte JBL', 'quantity': 1, 'price': 35000.0},
            {'name': 'Câble audio', 'quantity': 2, 'price': 4500.0},
          ],
        },
        {
          'id': '11',
          'orderId': 'CMD-011',
          'clientName': 'Thomas Mobutu',
          'total': 36000.0,
          'date': now.subtract(const Duration(days: 15)),
          'items': [
            {'name': 'Drone DJI Mini', 'quantity': 1, 'price': 36000.0},
          ],
        },
        {
          'id': '12',
          'orderId': 'CMD-012',
          'clientName': 'Nathalie Kabila',
          'total': 48000.0,
          'date': now.subtract(const Duration(days: 18)),
          'items': [
            {'name': 'Appareil photo Canon', 'quantity': 1, 'price': 40000.0},
            {'name': 'Carte mémoire 64GB', 'quantity': 1, 'price': 8000.0},
          ],
        },
        {
          'id': '13',
          'orderId': 'CMD-013',
          'clientName': 'Pierre Tshisekedi',
          'total': 52000.0,
          'date': now.subtract(const Duration(days: 20)),
          'items': [
            {'name': 'TV LED 32 pouces', 'quantity': 1, 'price': 52000.0},
          ],
        },
      ];

      final semesterSales = [
        ...monthlySales,
        {
          'id': '14',
          'orderId': 'CMD-014',
          'clientName': 'François Lumumba',
          'total': 75000.0,
          'date': now.subtract(const Duration(days: 35)),
          'items': [
            {'name': 'Réfrigérateur', 'quantity': 1, 'price': 60000.0},
            {'name': 'Machine à laver', 'quantity': 1, 'price': 15000.0},
          ],
        },
        {
          'id': '15',
          'orderId': 'CMD-015',
          'clientName': 'Isabelle Kasa-Vubu',
          'total': 61000.0,
          'date': now.subtract(const Duration(days: 42)),
          'items': [
            {'name': 'Micro-ondes', 'quantity': 1, 'price': 35000.0},
            {'name': 'Mixeur électrique', 'quantity': 1, 'price': 26000.0},
          ],
        },
        {
          'id': '16',
          'orderId': 'CMD-016',
          'clientName': 'Henri Mobutu',
          'total': 54000.0,
          'date': now.subtract(const Duration(days: 50)),
          'items': [
            {'name': 'Vélo électrique', 'quantity': 1, 'price': 54000.0},
          ],
        },
        {
          'id': '17',
          'orderId': 'CMD-017',
          'clientName': 'Catherine Kabila',
          'total': 68000.0,
          'date': now.subtract(const Duration(days: 60)),
          'items': [
            {'name': 'Aspirateur robot', 'quantity': 1, 'price': 50000.0},
            {'name': 'Batterie de rechange', 'quantity': 1, 'price': 18000.0},
          ],
        },
        {
          'id': '18',
          'orderId': 'CMD-018',
          'clientName': 'André Tshisekedi',
          'total': 59000.0,
          'date': now.subtract(const Duration(days: 75)),
          'items': [
            {'name': 'Console de jeu', 'quantity': 1, 'price': 45000.0},
            {'name': 'Manette supplémentaire', 'quantity': 1, 'price': 14000.0},
          ],
        },
        {
          'id': '19',
          'orderId': 'CMD-019',
          'clientName': 'Patricia Lumumba',
          'total': 72000.0,
          'date': now.subtract(const Duration(days: 90)),
          'items': [
            {'name': 'Smart TV 55 pouces', 'quantity': 1, 'price': 72000.0},
          ],
        },
      ];

      final yearlySales = [
        ...semesterSales,
        {
          'id': '20',
          'orderId': 'CMD-020',
          'clientName': 'Michel Kasa-Vubu',
          'total': 85000.0,
          'date': now.subtract(const Duration(days: 120)),
          'items': [
            {'name': 'Lave-vaisselle', 'quantity': 1, 'price': 70000.0},
            {'name': 'Détergent spécial', 'quantity': 3, 'price': 5000.0},
          ],
        },
        {
          'id': '21',
          'orderId': 'CMD-021',
          'clientName': 'Sylvie Mobutu',
          'total': 78000.0,
          'date': now.subtract(const Duration(days: 150)),
          'items': [
            {'name': 'Climatiseur portable', 'quantity': 1, 'price': 65000.0},
            {'name': 'Télécommande', 'quantity': 1, 'price': 5000.0},
            {'name': 'Filtre de rechange', 'quantity': 2, 'price': 4000.0},
          ],
        },
        {
          'id': '22',
          'orderId': 'CMD-022',
          'clientName': 'Bernard Kabila',
          'total': 92000.0,
          'date': now.subtract(const Duration(days: 180)),
          'items': [
            {'name': 'Home cinéma 5.1', 'quantity': 1, 'price': 80000.0},
            {'name': 'Câbles HDMI', 'quantity': 2, 'price': 6000.0},
          ],
        },
        {
          'id': '23',
          'orderId': 'CMD-023',
          'clientName': 'Monique Tshisekedi',
          'total': 65000.0,
          'date': now.subtract(const Duration(days: 210)),
          'items': [
            {'name': 'Robot aspirateur premium', 'quantity': 1, 'price': 65000.0},
          ],
        },
        {
          'id': '24',
          'orderId': 'CMD-024',
          'clientName': 'Laurent Lumumba',
          'total': 88000.0,
          'date': now.subtract(const Duration(days: 240)),
          'items': [
            {'name': 'Ordinateur de bureau', 'quantity': 1, 'price': 75000.0},
            {'name': 'Écran 24 pouces', 'quantity': 1, 'price': 13000.0},
          ],
        },
        {
          'id': '25',
          'orderId': 'CMD-025',
          'clientName': 'Chantal Kasa-Vubu',
          'total': 71000.0,
          'date': now.subtract(const Duration(days: 270)),
          'items': [
            {'name': 'Tablette iPad', 'quantity': 1, 'price': 60000.0},
            {'name': 'Stylet Apple Pencil', 'quantity': 1, 'price': 11000.0},
          ],
        },
        {
          'id': '26',
          'orderId': 'CMD-026',
          'clientName': 'Philippe Mobutu',
          'total': 96000.0,
          'date': now.subtract(const Duration(days: 300)),
          'items': [
            {'name': 'Smartphone haut de gamme', 'quantity': 1, 'price': 85000.0},
            {'name': 'Écouteurs sans fil', 'quantity': 1, 'price': 11000.0},
          ],
        },
      ];

      // Calculer les totaux
      final dailyTotal = dailySales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as double));
      final weeklyTotal = weeklySales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as double));
      final monthlyTotal = monthlySales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as double));
      final semesterTotal = semesterSales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as double));
      final yearlyTotal = yearlySales.fold<double>(0.0, (sum, sale) => sum + (sale['total'] as double));

      return {
        'success': true,
        'daily': {
          'total': dailyTotal,
          'count': dailySales.length,
          'sales': dailySales,
        },
        'weekly': {
          'total': weeklyTotal,
          'count': weeklySales.length,
          'sales': weeklySales,
        },
        'monthly': {
          'total': monthlyTotal,
          'count': monthlySales.length,
          'sales': monthlySales,
        },
        'semester': {
          'total': semesterTotal,
          'count': semesterSales.length,
          'sales': semesterSales,
        },
        'yearly': {
          'total': yearlyTotal,
          'count': yearlySales.length,
          'sales': yearlySales,
        },
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

