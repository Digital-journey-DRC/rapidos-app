// import 'package:flutter/material.dart';
// import 'package:immo/cubit/auth_cubit.dart';

// class VendeurOrder extends StatefulWidget {
//   const VendeurOrder({super.key});

//   @override
//   State<VendeurOrder> createState() => _VendeurOrderState();
// }

// class _VendeurOrderState extends State<VendeurOrder> {
//   @override
//   Widget build(BuildContext context) {
//     return _buildVendeurOrders( context);
//   }
// }



//   Widget _buildVendeurOrders(context) {
//     final authState = context.read<AuthCubit>().state;
//     if (authState is! AuthSuccess || authState.user == null) {
//       return const Center(
//         child: Text('Veuillez vous connecter pour voir vos commandes'),
//       );
//     }

//     final userId = authState.user!['id']?.toString() ?? '';

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('carts').snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           print('Erreur Firestore: ${snapshot.error}');
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, size: 50, color: Colors.red),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Erreur: ${snapshot.error}',
//                   style: const TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           );
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingShimmer();
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.inbox,
//                     size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
//                 const SizedBox(height: 18),
//                 const Text(
//                   'Aucune commande reçue',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primary),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Filtrer les commandes côté client
//         final filteredDocs = snapshot.data!.docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (data['items'] == null) return false;

//           final items = data['items'] as List;
//           return items.any((item) {
//             if (item is Map) {
//               return item['idVendeur'] == userId;
//             }
//             return false;
//           });
//         }).toList();

//         if (filteredDocs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.inbox,
//                     size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
//                 const SizedBox(height: 18),
//                 const Text(
//                   'Aucune commande reçue',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primary),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Trier les commandes par date
//         filteredDocs.sort((a, b) {
//           final aData = a.data() as Map<String, dynamic>;
//           final bData = b.data() as Map<String, dynamic>;
//           final aTimestamp = aData['timestamp'] as Timestamp?;
//           final bTimestamp = bData['timestamp'] as Timestamp?;

//           if (aTimestamp == null && bTimestamp == null) return 0;
//           if (aTimestamp == null) return 1;
//           if (bTimestamp == null) return -1;

//           return bTimestamp.compareTo(aTimestamp); // Tri décroissant
//         });

//         return ListView.separated(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//           separatorBuilder: (_, __) => const SizedBox(height: 8),
//           itemCount: filteredDocs.length,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemBuilder: (context, index) {
//             try {
//               final doc = filteredDocs[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final status = data['status']?.toString() ?? 'pending';
//               final timestamp = data['timestamp'] as Timestamp?;
//               final adresse =
//                   data['adresse']?.toString() ?? 'Adresse non spécifiée';

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 10,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(18),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => OrderDetailsScreen(
//                           orderData: data,
//                           orderId: doc.id,
//                         ),
//                       ),
//                     );
//                   },
//                   child: Column(
//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Timeline
//                           Container(
//                             width: 6,
//                             height: 110,
//                             margin: const EdgeInsets.only(
//                                 right: 10, top: 10, bottom: 10),
//                             decoration: BoxDecoration(
//                               color: _statusColor(status),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           // Image produit
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 top: 16, left: 0, right: 10),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(14),
//                               child: data['items'] != null &&
//                                       (data['items'] as List).isNotEmpty
//                                   ? Image.network(
//                                       (data['items'] as List)[0]['imagePath'] ??
//                                           'https://via.placeholder.com/80',
//                                       width: 70,
//                                       height: 70,
//                                       fit: BoxFit.cover,
//                                       errorBuilder:
//                                           (context, error, stackTrace) {
//                                         return Container(
//                                           width: 70,
//                                           height: 70,
//                                           color: Colors.grey.shade200,
//                                           child: const Icon(Icons.image,
//                                               color: Colors.grey),
//                                         );
//                                       },
//                                     )
//                                   : Container(
//                                       width: 70,
//                                       height: 70,
//                                       color: Colors.grey.shade200,
//                                       child: const Icon(Icons.image,
//                                           color: Colors.grey),
//                                     ),
//                             ),
//                           ),
//                           // Détails commande
//                           Expanded(
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 16, horizontal: 0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           data['items'] != null &&
//                                                   (data['items'] as List)
//                                                       .isNotEmpty
//                                               ? (data['items'] as List)[0]
//                                                       ['name'] ??
//                                                   'Produit'
//                                               : 'Produit',
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 12, vertical: 4),
//                                         decoration: BoxDecoration(
//                                           color: _statusColor(status)
//                                               .withOpacity(0.1),
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: Text(
//                                           _translateStatus(status),
//                                           style: TextStyle(
//                                             color: _statusColor(status),
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     adresse,
//                                     style: TextStyle(
//                                       color: Colors.grey.shade600,
//                                       fontSize: 14,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.calendar_today,
//                                           size: 14, color: AppColors.primary),
//                                       const SizedBox(width: 4),
//                                       Text(
//                                         _formatDate(timestamp),
//                                         style: const TextStyle(fontSize: 13),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       const Icon(Icons.shopping_cart,
//                                           size: 14, color: AppColors.primary),
//                                       const SizedBox(width: 4),
//                                       Text(
//                                         '${(data['items'] as List?)?.length ?? 0} article${((data['items'] as List?)?.length ?? 0) > 1 ? 's' : ''}',
//                                         style: const TextStyle(fontSize: 13),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       // Contenu existant
//                       if (status == 'prêt à expédier' &&
//                           data['packagePhoto'] != null)
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Photo du colis:',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                   color: AppColors.primary,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               GestureDetector(
//                                 onTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (BuildContext context) {
//                                       return Dialog(
//                                         insetPadding: EdgeInsets.zero,
//                                         child: Stack(
//                                           children: [
//                                             InteractiveViewer(
//                                               minScale: 0.5,
//                                               maxScale: 4.0,
//                                               child: Image.network(
//                                                 data['packagePhoto'],
//                                                 fit: BoxFit.contain,
//                                                 width: MediaQuery.of(context)
//                                                     .size
//                                                     .width,
//                                                 height: MediaQuery.of(context)
//                                                     .size
//                                                     .height,
//                                               ),
//                                             ),
//                                             Positioned(
//                                               top: 10,
//                                               right: 10,
//                                               child: IconButton(
//                                                 icon: const Icon(Icons.close,
//                                                     color: Colors.white),
//                                                 onPressed: () =>
//                                                     Navigator.pop(context),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 },
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: Image.network(
//                                     data['packagePhoto'],
//                                     width: double.infinity,
//                                     height: 150,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Container(
//                                         width: double.infinity,
//                                         height: 150,
//                                         color: Colors.grey.shade200,
//                                         child: const Icon(Icons.image,
//                                             color: Colors.grey),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       // Bouton pour accepter la livraison
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Column(
//                           children: [
//                             if (status.toLowerCase() == 'pending') ...[
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: ElevatedButton(
//                                         onPressed: () async {
//                                           try {
//                                             await FirebaseFirestore.instance
//                                                 .collection('carts')
//                                                 .doc(doc.id)
//                                                 .update({
//                                               'status':
//                                                   'colis en cours de préparation',
//                                               'timestamp':
//                                                   FieldValue.serverTimestamp(),
//                                             });

//                                             if (mounted) {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                   content: Text(
//                                                       'Commande acceptée avec succès'),
//                                                   backgroundColor: Colors.green,
//                                                 ),
//                                               );
//                                             }
//                                           } catch (e) {
//                                             if (mounted) {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 SnackBar(
//                                                   content: Text('Erreur: $e'),
//                                                   backgroundColor: Colors.red,
//                                                 ),
//                                               );
//                                             }
//                                           }
//                                         },
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: AppColors.primary,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(8),
//                                           ),
//                                           minimumSize:
//                                               const Size(double.infinity, 40),
//                                         ),
//                                         child: const Text(
//                                           'Accepter',
//                                           style: TextStyle(color: Colors.white),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Expanded(
//                                       child: ElevatedButton(
//                                         onPressed: () async {
//                                           // Afficher la boîte de dialogue pour la raison du rejet
//                                           final TextEditingController
//                                               reasonController =
//                                               TextEditingController();
//                                           bool? confirmed =
//                                               await showDialog<bool>(
//                                             context: context,
//                                             builder: (BuildContext context) {
//                                               return StatefulBuilder(
//                                                 builder: (context, setState) {
//                                                   return AlertDialog(
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               16),
//                                                     ),
//                                                     title: Row(
//                                                       children: [
//                                                         const Icon(
//                                                             Icons
//                                                                 .warning_amber_rounded,
//                                                             color: Colors.red),
//                                                         const SizedBox(
//                                                             width: 8),
//                                                         const Text(
//                                                           'Rejeter la commande',
//                                                           style: TextStyle(
//                                                             fontSize: 18,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     content: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         const Text(
//                                                           'Veuillez indiquer la raison du rejet de cette commande.',
//                                                           style: TextStyle(
//                                                             color: Colors.grey,
//                                                             fontSize: 14,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 16),
//                                                         TextField(
//                                                           controller:
//                                                               reasonController,
//                                                           decoration:
//                                                               InputDecoration(
//                                                             hintText:
//                                                                 'Entrez la raison du rejet',
//                                                             border:
//                                                                 OutlineInputBorder(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           8),
//                                                             ),
//                                                             filled: true,
//                                                             fillColor: Colors
//                                                                 .grey.shade50,
//                                                             prefixIcon: const Icon(
//                                                                 Icons.edit_note,
//                                                                 color: Colors
//                                                                     .grey),
//                                                             errorText:
//                                                                 reasonController
//                                                                         .text
//                                                                         .isEmpty
//                                                                     ? 'Ce champ est obligatoire'
//                                                                     : null,
//                                                           ),
//                                                           maxLines: 3,
//                                                           onChanged: (value) {
//                                                             setState(
//                                                                 () {}); // Pour mettre à jour la validation en temps réel
//                                                           },
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     actions: [
//                                                       TextButton(
//                                                         onPressed: () =>
//                                                             Navigator.pop(
//                                                                 context, false),
//                                                         child: const Text(
//                                                           'ANNULER',
//                                                           style: TextStyle(
//                                                               color:
//                                                                   Colors.grey),
//                                                         ),
//                                                       ),
//                                                       ElevatedButton(
//                                                         onPressed:
//                                                             reasonController
//                                                                     .text
//                                                                     .trim()
//                                                                     .isEmpty
//                                                                 ? null
//                                                                 : () {
//                                                                     Navigator.pop(
//                                                                         context,
//                                                                         true);
//                                                                   },
//                                                         style: ElevatedButton
//                                                             .styleFrom(
//                                                           backgroundColor:
//                                                               Colors.red,
//                                                           disabledBackgroundColor:
//                                                               Colors.red
//                                                                   .withOpacity(
//                                                                       0.5),
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         8),
//                                                           ),
//                                                         ),
//                                                         child: const Text(
//                                                           'REJETER',
//                                                           style: TextStyle(
//                                                               color:
//                                                                   Colors.white),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   );
//                                                 },
//                                               );
//                                             },
//                                           );

//                                           if (confirmed == true &&
//                                               reasonController.text
//                                                   .trim()
//                                                   .isNotEmpty) {
//                                             try {
//                                               await FirebaseFirestore.instance
//                                                   .collection('carts')
//                                                   .doc(doc.id)
//                                                   .update({
//                                                 'status': 'rejected',
//                                                 'rejectionReason':
//                                                     reasonController.text
//                                                         .trim(),
//                                                 'timestamp': FieldValue
//                                                     .serverTimestamp(),
//                                               });

//                                               if (mounted) {
//                                                 ScaffoldMessenger.of(context)
//                                                     .showSnackBar(
//                                                   const SnackBar(
//                                                     content: Text(
//                                                         'Commande rejetée'),
//                                                     backgroundColor: Colors.red,
//                                                   ),
//                                                 );
//                                               }
//                                             } catch (e) {
//                                               if (mounted) {
//                                                 ScaffoldMessenger.of(context)
//                                                     .showSnackBar(
//                                                   SnackBar(
//                                                     content: Text('Erreur: $e'),
//                                                     backgroundColor: Colors.red,
//                                                   ),
//                                                 );
//                                               }
//                                             }
//                                           }
//                                         },
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.red,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(8),
//                                           ),
//                                           minimumSize:
//                                               const Size(double.infinity, 40),
//                                         ),
//                                         child: const Text(
//                                           'REJETER',
//                                           style: TextStyle(color: Colors.white),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Padding(
//                                 padding:
//                                     const EdgeInsets.symmetric(horizontal: 8.0),
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     // Afficher le popup de contact
//                                     showDialog(
//                                       context: context,
//                                       builder: (BuildContext context) {
//                                         return Dialog(
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(16),
//                                           ),
//                                           child: Container(
//                                             padding: const EdgeInsets.all(20),
//                                             child: Column(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 const Text(
//                                                   'Contacter le client',
//                                                   style: TextStyle(
//                                                     fontSize: 18,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 8),
//                                                 Text(
//                                                   data['client'] ?? 'Client',
//                                                   style: const TextStyle(
//                                                     fontSize: 16,
//                                                     color: AppColors.primary,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 20),
//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceEvenly,
//                                                   children: [
//                                                     // Bouton Appel normal
//                                                     ElevatedButton(
//                                                       onPressed: () {
//                                                         final phoneNumber =
//                                                             data['phone'] ?? '';
//                                                         if (phoneNumber
//                                                             .isNotEmpty) {
//                                                           launchUrl(Uri.parse(
//                                                               'tel:$phoneNumber'));
//                                                         } else {
//                                                           ScaffoldMessenger.of(
//                                                                   context)
//                                                               .showSnackBar(
//                                                             const SnackBar(
//                                                               content: Text(
//                                                                   'Numéro de téléphone non disponible'),
//                                                               backgroundColor:
//                                                                   Colors.red,
//                                                             ),
//                                                           );
//                                                         }
//                                                         Navigator.pop(context);
//                                                       },
//                                                       style: ElevatedButton
//                                                           .styleFrom(
//                                                         backgroundColor:
//                                                             AppColors.primary,
//                                                         shape:
//                                                             RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(8),
//                                                         ),
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal: 20,
//                                                                 vertical: 12),
//                                                       ),
//                                                       child: const Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           Icon(Icons.phone,
//                                                               color:
//                                                                   Colors.white),
//                                                           SizedBox(width: 8),
//                                                           Text(
//                                                             'Appeler',
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     // Bouton WhatsApp
//                                                     ElevatedButton(
//                                                       onPressed: () {
//                                                         final phoneNumber =
//                                                             data['phone'] ?? '';
//                                                         if (phoneNumber
//                                                             .isNotEmpty) {
//                                                           final whatsappUrl =
//                                                               'https://wa.me/$phoneNumber';
//                                                           launchUrl(Uri.parse(
//                                                               whatsappUrl));
//                                                         } else {
//                                                           ScaffoldMessenger.of(
//                                                                   context)
//                                                               .showSnackBar(
//                                                             const SnackBar(
//                                                               content: Text(
//                                                                   'Numéro de téléphone non disponible'),
//                                                               backgroundColor:
//                                                                   Colors.red,
//                                                             ),
//                                                           );
//                                                         }
//                                                         Navigator.pop(context);
//                                                       },
//                                                       style: ElevatedButton
//                                                           .styleFrom(
//                                                         backgroundColor:
//                                                             Colors.green,
//                                                         shape:
//                                                             RoundedRectangleBorder(
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(8),
//                                                         ),
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal: 20,
//                                                                 vertical: 12),
//                                                       ),
//                                                       child: const Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           Icon(Icons.message,
//                                                               color:
//                                                                   Colors.white),
//                                                           SizedBox(width: 8),
//                                                           Text(
//                                                             'WhatsApp',
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(height: 16),
//                                                 TextButton(
//                                                   onPressed: () =>
//                                                       Navigator.pop(context),
//                                                   child: const Text(
//                                                     'ANNULER',
//                                                     style: TextStyle(
//                                                         color: Colors.grey),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     );
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     minimumSize:
//                                         const Size(double.infinity, 40),
//                                   ),
//                                   child: const Text(
//                                     'Contacter',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                             if (status == 'colis en cours de préparation') ...[
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     _showExpeditionDialog(context, doc.id);
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppColors.primary,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     minimumSize:
//                                         const Size(double.infinity, 40),
//                                   ),
//                                   child: const Text(
//                                     'Expédier',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             } catch (e) {
//               print('Erreur lors de l\'affichage de la commande: $e');
//               return Container(
//                 padding: const EdgeInsets.all(16),
//                 margin: const EdgeInsets.only(bottom: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: const Text(
//                   'Erreur lors de l\'affichage de la commande',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               );
//             }
//           },
//         );
//       },
//     );
//   }

