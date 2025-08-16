import 'package:flutter/material.dart';
import '../services/version_service.dart';

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  
  const VersionCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _hasCheckedVersion = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    if (!_hasCheckedVersion) {
      _hasCheckedVersion = true;
      try {
        await VersionService.checkForUpdate(context);
      } catch (e) {
        print('Erreur lors de la vérification de version: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
