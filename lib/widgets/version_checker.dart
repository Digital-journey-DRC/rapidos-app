import 'package:flutter/material.dart';
import '../services/version_service.dart';

class VersionChecker extends StatefulWidget {
  final Widget child;
  
  const VersionChecker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      await VersionService.checkForUpdate(context);
    } catch (e) {
      print('Erreur lors de la vérification de version: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isChecking)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
