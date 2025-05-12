import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubits/utility_bill/utility_bill_state.dart';
import 'package:immo/services/utility_bill_service.dart';

class UtilityBillCubit extends Cubit<UtilityBillState> {
  final UtilityBillService _utilityBillService;

  UtilityBillCubit(this._utilityBillService) : super(UtilityBillInitial());

  Future<void> createUtilityBill({
    required String token,
    required String buildingId,
    required String type,
    required double value,
    required String currency,
  }) async {
    try {
      emit(UtilityBillLoading());
      print('Création de facture - Paramètres: buildingId=$buildingId, type=$type, value=$value, currency=$currency');
      final bill = await _utilityBillService.createUtilityBill(
        token: token,
        buildingId: buildingId,
        type: type,
        value: value,
        currency: currency,
      );
      print('Facture créée avec succès: $bill');
      emit(UtilityBillCreated(
        message: 'Facture créée avec succès',
        bill: bill,
      ));
    } catch (e) {
      print('Erreur lors de la création de facture: $e');
      emit(UtilityBillError(message: e.toString()));
    }
  }

  Future<void> getUtilityBills({
    required String token,
    required String buildingId,
  }) async {
    try {
      emit(UtilityBillLoading());
      print('Récupération des factures - buildingId: $buildingId');
      final bills = await _utilityBillService.getUtilityBills(
        token: token,
        buildingId: buildingId,
      );
      print('Factures récupérées: $bills');
      print('Type de données reçues: ${bills.runtimeType}');
      print('Nombre de factures: ${bills.length}');
      emit(UtilityBillsLoaded(bills: bills));
    } catch (e) {
      print('Erreur lors de la récupération des factures: $e');
      emit(UtilityBillError(message: e.toString()));
    }
  }


  
  Future<void> getUtilityBillsByApartment({
    required String token,
    required String apartmentId,
  }) async {
    try {
      emit(UtilityBillLoading());
      print('Récupération des factures par appartement - apartmentId: $apartmentId');
      print('Token utilisé: ${token.substring(0, 10)}...');
      
      final bills = await _utilityBillService.getUtilityBillsByApartment(
        token: token,
        apartmentId: apartmentId,
      );
      

      
      
      print('Factures récupérées pour l\'appartement: $bills');
      print('Type de données reçues: ${bills.runtimeType}');
      print('Nombre de factures: ${bills.length}');
      
      if (bills.isEmpty) {
        print('Attention: Aucune facture trouvée pour cet appartement');
      }
      
      emit(UtilityBillsLoaded(bills: bills));
      print('État émis: UtilityBillsLoaded avec ${bills.length} factures');
    } catch (e) {
      print('Erreur lors de la récupération des factures par appartement: $e');
      print('Trace d\'erreur: ${e is Exception ? e.toString() : "Non disponible"}');
      emit(UtilityBillError(message: e.toString()));
      print('État émis: UtilityBillError');
    }
  }
}
