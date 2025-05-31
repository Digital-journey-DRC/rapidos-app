import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class CartState {
  final List<Map<String, dynamic>> items;
  CartState(this.items);
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState([])) {
    loadCart();
  }

  Future<void> loadCart() async {
    final box = await Hive.openBox('cartBox');
    final List<String> items = (box.get('cart_items') as List?)?.cast<String>() ?? [];
    emit(CartState(items.map((e) => jsonDecode(e) as Map<String, dynamic>).toList()));
  }

  Future<bool> addToCart(Map<String, dynamic> newItem) async {
    final box = await Hive.openBox('cartBox');
    final List<String> items = (box.get('cart_items') as List?)?.cast<String>() ?? [];
    bool productExists = false;
    for (int i = 0; i < items.length; i++) {
      final existingItem = jsonDecode(items[i]);
      if (existingItem['name'] == newItem['name']) {
        final currentQty = (existingItem['quantity'] is int)
            ? existingItem['quantity']
            : int.tryParse(existingItem['quantity'].toString()) ?? 1;
        final stock = existingItem['stock'] ?? newItem['stock'] ?? 1;
        final newQty = currentQty + (newItem['quantity'] as int);
        if (newQty > stock) {
          // Dépasse le stock
          return false;
        }
        existingItem['quantity'] = newQty;
        items[i] = jsonEncode(existingItem);
        productExists = true;
        break;
      }
    }
    if (!productExists) {
      final stock = newItem['stock'] ?? 1;
      if ((newItem['quantity'] as int) > stock) {
        // Dépasse le stock
        return false;
      }
      items.add(jsonEncode(newItem));
    }
    await box.put('cart_items', items);
    await loadCart();
    return true;
  }

  Future<void> removeFromCart(String name) async {
    final box = await Hive.openBox('cartBox');
    final List<String> items = (box.get('cart_items') as List?)?.cast<String>() ?? [];
    items.removeWhere((item) => jsonDecode(item)['name'] == name);
    await box.put('cart_items', items);
    await loadCart();
  }

  Future<bool> updateQuantity(String name, int newQuantity) async {
    final box = await Hive.openBox('cartBox');
    final List<String> items = (box.get('cart_items') as List?)?.cast<String>() ?? [];
    for (int i = 0; i < items.length; i++) {
      final existingItem = jsonDecode(items[i]);
      if (existingItem['name'] == name) {
        final stock = existingItem['stock'] ?? 1;
        if (newQuantity > stock) {
          // Dépasse le stock
          return false;
        }
        existingItem['quantity'] = newQuantity;
        items[i] = jsonEncode(existingItem);
        break;
      }
    }
    await box.put('cart_items', items);
    await loadCart();
    return true;
  }

  Future<void> clearCart() async {
    final box = await Hive.openBox('cartBox');
    await box.put('cart_items', <String>[]);
    await loadCart();
  }
} 