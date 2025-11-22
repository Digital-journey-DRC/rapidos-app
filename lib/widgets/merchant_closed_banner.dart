import 'package:flutter/material.dart';
import 'package:immo/models/merchant_hours.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Widget pour afficher un message quand la boutique est fermée
class MerchantClosedBanner extends StatefulWidget {
  const MerchantClosedBanner({Key? key}) : super(key: key);

  @override
  State<MerchantClosedBanner> createState() => _MerchantClosedBannerState();
}

class _MerchantClosedBannerState extends State<MerchantClosedBanner> {
  MerchantServiceConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('merchant_service_config');
      
      if (configJson != null) {
        _config = MerchantServiceConfig.fromJson(jsonDecode(configJson));
      } else {
        _config = MerchantServiceConfig.getDefault();
      }
    } catch (e) {
      _config = MerchantServiceConfig.getDefault();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const SizedBox.shrink();
    }

    final isClosed = !_config!.isCurrentlyOpen();

    if (!isClosed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ce marchand est actuellement fermé et ne peut pas effectuer de livraison pour le moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

