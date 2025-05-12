import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:immo/widgets/custom_skeletons.dart';

class MaintenanceMonitoring extends StatefulWidget {
  const MaintenanceMonitoring({super.key});

  @override
  State<MaintenanceMonitoring> createState() => _MaintenanceMonitoringState();
}

class _MaintenanceMonitoringState extends State<MaintenanceMonitoring> {
  List<dynamic> maintenances = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
  }

  Future<void> _loadMaintenances() async {
    try {
      final authState = context.read<AuthCubit>();
      final currentState = authState.state;
      if (currentState is! AuthSuccess) {
        setState(() {
          error = 'Veuillez vous connecter pour accéder aux maintenances';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://68.183.30.146:8000/api/v1/maintenances/owner'),
        headers: {'Authorization': 'Bearer ${currentState.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          maintenances = data['data'];
          isLoading = false;
        });
      } else { 
        setState(() {
          error = 'Erreur lors du chargement des maintenances';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur de connexion';
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    }
  }

  void _launchWhatsApp(String phoneNumber) async {
    // Enlever le + et tous les caractères non numériques du numéro
    String cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(RegExp(r'[^0-9]'), '');
    
    final Uri uri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    } else {
      // Si WhatsApp n'est pas installé, essayer d'ouvrir WhatsApp Web
      final webUri = Uri.parse('https://wa.me/$cleanPhone');
      if (await launcher.canLaunchUrl(webUri)) {
        await launcher.launchUrl(webUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    }
  }

  Future<void> _deleteMaintenance(String maintenanceId) async {
    try {
      final authState = context.read<AuthCubit>();
      final currentState = authState.state;
      if (currentState is! AuthSuccess) return;

      final response = await http.delete(
        Uri.parse('http://68.183.30.146:8000/api/v1/maintenances/$maintenanceId'),
        headers: {
          'Authorization': 'Bearer ${currentState.token}',
        },
      );

      if (response.statusCode == 200) {
        _loadMaintenances(); // Recharger la liste après la suppression
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance Résolue avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la résolution')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.buttonColor,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              const SkeletonLine(
                style: SkeletonLineStyle(
                  width: 180,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Maintenance item skeletons
              for (int i = 0; i < 5; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and status row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 180,
                                height: 18,
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 60,
                                  height: 12,
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Description skeleton
                        const SkeletonParagraph(
                          style: SkeletonLineStyle(
                            height: 12,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          lines: 2,
                          spacing: 8,
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        // Date row skeleton
                        const SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 120,
                            height: 12,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/no-connect.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(error!),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Maintenances',
            style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadMaintenances,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: maintenances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle,
                    size: 120,
                    color: AppColors.buttonColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune maintenance en cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les maintenances apparaîtront ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: maintenances.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
          final maintenance = maintenances[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: AppColors.buttonColor,
                width: 2,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          maintenance['title'] ?? 'Sans titre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 12),
                  if (maintenance['apartmentId'] != null && 
                      maintenance['apartmentId']['buildingId'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.business, color: AppColors.buttonColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            maintenance['apartmentId']['buildingId']['name'] ?? 'Immeuble sans nom',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buttonColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (maintenance['apartmentId']['buildingId']['address'] != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [
                                maintenance['apartmentId']['buildingId']['address']['street'],
                                maintenance['apartmentId']['buildingId']['address']['city'],
                                maintenance['apartmentId']['buildingId']['address']['country'],
                              ].where((e) => e != null).join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 8),
                  if (maintenance['apartmentId'] != null)
                    Row(
                      children: [
                        const Icon(Icons.apartment, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Appartement ${maintenance['apartmentId']['number'] ?? ''}'
                          '${maintenance['apartmentId']['floor'] != null ? ' - Étage ${maintenance['apartmentId']['floor']}' : ''}'
                          '${maintenance['apartmentId']['type'] != null ? ' (${maintenance['apartmentId']['type']})' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          maintenance['description'] ?? 'Aucune description',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${_formatDate(maintenance['date'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${_formatDate(maintenance['date'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (maintenance['cost']['amount'] > 0)
                        Text(
                          '${maintenance['cost']['amount']} ${maintenance['cost']['currency']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonColor,
                          ),
                        ),
                    ],
                  ),
                  if (maintenance['images'] != null && (maintenance['images'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (maintenance['images'] as List).length,
                        itemBuilder: (context, imageIndex) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(maintenance['images'][imageIndex]),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.buttonColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        maintenance['images'][imageIndex],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (maintenance['contactInfo'] != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          maintenance['contactInfo']['name'] ?? 'Non spécifié',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 100,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchCall(maintenance['contactInfo']['phone']),
                            icon: const Icon(Icons.phone, color: Colors.white, size: 16),
                            label: const Text('Appeler', style: TextStyle(fontSize: 9)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchWhatsApp(maintenance['contactInfo']['phone']),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 16),
                            label: const Text('WhatsApp', style: TextStyle(fontSize: 9)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        if (maintenance['status'] != 'résolu')
                          SizedBox(
                            width: 100,
                            child: ElevatedButton.icon(
                              onPressed: () => _deleteMaintenance(maintenance['_id']),
                              icon: const Icon(Icons.done, color: Colors.white, size: 16),
                              label: const Text('Résolue', style: TextStyle(fontSize: 9)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}