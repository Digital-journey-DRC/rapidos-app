import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RentBookContrat extends StatefulWidget {
   RentBookContrat({super.key, required this.rentbook});
  final rentbook;


  @override
  State<RentBookContrat> createState() => _RentBookContratState();
}

class _RentBookContratState extends State<RentBookContrat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: InkWell(
      onTap: () {
        Navigator.of(context).pop();
      },
      
      child: const Text("Contrat"))));
  }
}