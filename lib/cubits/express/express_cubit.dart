import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/express_service.dart';
import 'express_state.dart';

class ExpressCubit extends Cubit<ExpressState> {
  final ExpressService _expressService = ExpressService();

  ExpressCubit() : super(ExpressInitial());

  Future<void> loadClients() async {
    try {
      emit(ExpressLoading());
      final clients = await _expressService.getClients();
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> loadClientsByVendeur(String vendeurId) async {
    print('🔄 ExpressCubit.loadClientsByVendeur() - Début avec vendeurId: $vendeurId');
    try {
      emit(ExpressLoading());
      print('📤 Émission de ExpressLoading');
      
      final clients = await _expressService.getClientsByVendeur(vendeurId);
      print('📥 Clients reçus du service: ${clients.length} clients');
      
      emit(ClientsLoaded(clients));
      print('📤 Émission de ClientsLoaded avec ${clients.length} clients');
    } catch (e) {
      print('❌ Erreur dans loadClientsByVendeur: $e');
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> createClient(Map<String, dynamic> clientData) async {
    print('🔄 ExpressCubit.createClient() - Début');
    print('📝 Données reçues: $clientData');
    
    try {
      emit(ExpressLoading());
      print('📤 Émission de ExpressLoading');
      
      final clientId = await _expressService.createClient(clientData);
      print('✅ Client créé avec succès, ID: $clientId');
      
      emit(ClientCreated(clientId));
      print('📤 Émission de ClientCreated avec ID: $clientId');
    } catch (e) {
      print('❌ Erreur dans createClient: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> createExpressOrder(Map<String, dynamic> orderData) async {
    try {
      emit(ExpressLoading());
      final orderId = await _expressService.createExpressOrder(orderData);
      emit(ExpressOrderCreated(orderId));
    } catch (e) {
      print('❌ Erreur lors de la création de la commande express: $e');
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> fixClientsWithoutVendeurId() async {
    try {
      print('🔧 ExpressCubit.fixClientsWithoutVendeurId() - Début');
      await _expressService.fixClientsWithoutVendeurId();
      print('✅ Correction terminée');
    } catch (e) {
      print('❌ Erreur lors de la correction: $e');
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> loadExpressOrders() async {
    try {
      emit(ExpressLoading());
      final orders = await _expressService.getExpressOrders();
      emit(ExpressOrdersLoaded(orders));
    } catch (e) {
      print('❌ Erreur lors du chargement des commandes express: $e');
      emit(ExpressError(e.toString()));
    }
  }

  Future<void> loadExpressOrdersByVendeur(String vendeurId) async {
    try {
      emit(ExpressLoading());
      final orders = await _expressService.getExpressOrdersByVendeur(vendeurId);
      emit(ExpressOrdersLoaded(orders));
    } catch (e) {
      print('❌ Erreur lors du chargement des commandes express: $e');
      emit(ExpressError(e.toString()));
    }
  }
} 