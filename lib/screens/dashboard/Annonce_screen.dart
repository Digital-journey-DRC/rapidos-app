import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/listing_cubit.dart';

class AnnonceScreen extends StatefulWidget {
  final String annonceId;
  const AnnonceScreen({super.key, required this.annonceId});

  @override
  State<AnnonceScreen> createState() => _AnnonceScreenState();
}

class _AnnonceScreenState extends State<AnnonceScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les détails de l'annonce au démarrage
    // context.read<ListingCubit>().getListingDetails(widget.annonceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'annonce'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Text('data'),
    );
  }
}