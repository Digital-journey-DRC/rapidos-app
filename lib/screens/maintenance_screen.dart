import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants.dart';
import '../cubit/maintenance_cubit.dart';
import 'maintenance_step2.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.apartmentId});

  final String apartmentId;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<MaintenanceCubit>().createMaintenance(
            title: _titleController.text,
            description: _descriptionController.text,
            apartmentId: widget.apartmentId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle maintenance'),
        backgroundColor: Colors.white,
      ),
      body: BlocConsumer<MaintenanceCubit, MaintenanceState>(
        listener: (context, state) {
          if (state is MaintenanceSuccess && state.maintenanceId != null) {
            print('Navigation triggered with maintenanceId: ${state.maintenanceId}'); // Debug log
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MaintenanceStep2Screen(
                  maintenanceId: state.maintenanceId!,
                ),
              ),
            );
          } else if (state is MaintenanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: state is MaintenanceLoading ? null : _submitForm,
                      child: state is MaintenanceLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Suivant',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}