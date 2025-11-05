import 'package:flutter/material.dart';
import 'package:immo/constants.dart';

class StatusFilter extends StatelessWidget {
  final String selectedStatus;
  final Function(String?) onStatusChanged;
  final Color Function(String) statusColor;
  final String Function(String) translateStatus;

  const StatusFilter({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.statusColor,
    required this.translateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
        decoration: const InputDecoration(
          labelText: 'Filtrer par statut',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.filter_list, color: AppColors.primary),
        ),
        items: [
          'Tous',
          'pending',
          'colis en cours de préparation',
          'prêt à expédier',
          'en route pour livraison',
          'delivered',
          'cancelled',
          'rejected',
        ].map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status == 'Tous' ? 'Tous les statuts' : translateStatus(status),
              style: TextStyle(
                color: status == 'Tous' ? Colors.grey : statusColor(status),
              ),
            ),
          );
        }).toList(),
        onChanged: onStatusChanged,
      ),
    );
  }
} 