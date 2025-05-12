import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/listing_cubit.dart';
import 'package:immo/cubit/listing_state.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import '../widgets/image_viewer.dart';
import 'property_detail_screen.dart';
import '../repository/favorites_repository.dart';
import 'favoris_screen.dart';

// Énumération pour le type de propriété
enum PropertyType {
  apartmentForSale,
  apartmentForRent,
  houseForRent,
}

// Énumération pour la disponibilité
enum Availability {
  available,
  rented,
  sold,
  pending,
  unavailable,
}

class Property {
  final List images;
  final String title;
  final String details;
  final double price;
  final double pricePerMeter;
  final double rating;
  final int reviews;
  final DateTime publishedAt;
  final Availability availability;
  final PropertyType propertyType;
  final int bedrooms;
  final double surface;
  final String description;
  final int bathrooms;
  final String location;
  final String id;
  final Map<String, dynamic> publisher;

  Property({
    required this.images,
    required this.title,
    required this.details,
    required this.price,
    required this.pricePerMeter,
    required this.rating,
    required this.reviews,
    required this.publishedAt,
    required this.availability,
    required this.propertyType,
    required this.bedrooms,
    required this.surface,
    required this.description,
    required this.bathrooms,
    required this.location,
    required this.id,
    required this.publisher,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Ensure all values are correctly converted from any potential type
    return Property(
      id: json['id'] != null ? json['id'].toString() : '',
      images: json['images'] as List<dynamic>,
      title: json['title'] as String,
      details: json['details'] as String,
      price: (json['price'] as num).toDouble(),
      pricePerMeter: (json['pricePerMeter'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      availability: Availability.values.firstWhere(
        (e) => e.toString() == json['availability'],
        orElse: () => Availability.unavailable,
      ),
      propertyType: PropertyType.values.firstWhere(
        (e) => e.toString() == json['propertyType'],
        orElse: () => PropertyType.apartmentForRent,
      ),
      bedrooms: json['bedrooms'] as int,
      surface: (json['surface'] as num).toDouble(),
      description: json['description'] as String,
      bathrooms: json['bathrooms'] as int,
      location: json['location'] as String,
      publisher: json['publisher'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'images': images,
      'title': title,
      'details': details,
      'price': price,
      'pricePerMeter': pricePerMeter,
      'rating': rating,
      'reviews': reviews,
      'publishedAt': publishedAt.toIso8601String(),
      'availability': availability.toString(),
      'propertyType': propertyType.toString(),
      'bedrooms': bedrooms,
      'surface': surface,
      'description': description,
      'bathrooms': bathrooms,
      'location': location,
      'publisher': publisher,
    };
  }
}

class PropertyFilter {
  double? minPrice;
  double? maxPrice;
  int? minBedrooms;
  int? maxBedrooms;
  PropertyType? propertyType;
  Availability? availability;
  DateTime? publishedAfter;

  PropertyFilter({
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.maxBedrooms,
    this.propertyType,
    this.availability,
    this.publishedAfter,
  });

  bool matches(Property property) {
    if (minPrice != null && property.price < minPrice!) return false;
    if (maxPrice != null && property.price > maxPrice!) return false;
    if (minBedrooms != null && property.bedrooms < minBedrooms!) return false;
    if (maxBedrooms != null && property.bedrooms > maxBedrooms!) return false;
    if (propertyType != null && property.propertyType != propertyType)
      return false;
    if (availability != null && property.availability != availability)
      return false;
    if (publishedAfter != null &&
        property.publishedAt.isBefore(publishedAfter!)) return false;
    return true;
  }
}

class PropertySearchDelegate extends SearchDelegate<Property?> {
  final List<Property> properties;
  final Function(String) onSearch;
  final PropertyFilter filter;

  PropertySearchDelegate(this.properties, this.onSearch, this.filter);

  List<Property> _getFilteredProperties(String query) {
    if (query.isEmpty) return [];
    return properties.where((property) {
      bool matchesQuery =
          property.title.toLowerCase().contains(query.toLowerCase()) ||
              property.details.toLowerCase().contains(query.toLowerCase()) ||
              property.price.toString().contains(query);
      return matchesQuery && filter.matches(property);
    }).toList();
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.tune),
        onPressed: () {
          _showFilterDialog(context);
        },
      ),
      AnimatedOpacity(
        opacity: query.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ),
    ];
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          filter.minPrice = null;
                          filter.maxPrice = null;
                          filter.minBedrooms = null;
                          filter.maxBedrooms = null;
                          filter.propertyType = null;
                          filter.availability = null;
                          filter.publishedAfter = null;
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Type de propriété
                    const Text(
                      'Type de bien',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Appartement à vendre'),
                          selected: filter.propertyType ==
                              PropertyType.apartmentForSale,
                          onSelected: (selected) {
                            setState(() {
                              filter.propertyType = selected
                                  ? PropertyType.apartmentForSale
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Appartement à louer'),
                          selected: filter.propertyType ==
                              PropertyType.apartmentForRent,
                          onSelected: (selected) {
                            setState(() {
                              filter.propertyType = selected
                                  ? PropertyType.apartmentForRent
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Maison à louer'),
                          selected: filter.propertyType ==
                              PropertyType.houseForRent,
                          onSelected: (selected) {
                            setState(() {
                              filter.propertyType =
                                  selected ? PropertyType.houseForRent : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Prix
                    const Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              prefixText: '€',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: filter.minPrice?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setState(() {
                                filter.minPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              prefixText: '€',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: filter.maxPrice?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setState(() {
                                filter.maxPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nombre de chambres
                    const Text(
                      'Nombre de chambres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${index + 1}'),
                            selected: filter.minBedrooms == index + 1,
                            onSelected: (selected) {
                              setState(() {
                                filter.minBedrooms =
                                    selected ? index + 1 : null;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Disponibilité
                    const Text(
                      'Disponibilité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Disponible'),
                          selected: filter.availability ==
                              Availability.available,
                          onSelected: (selected) {
                            setState(() {
                              filter.availability =
                                  selected ? Availability.available : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Loué'),
                          selected: filter.availability == Availability.rented,
                          onSelected: (selected) {
                            setState(() {
                              filter.availability =
                                  selected ? Availability.rented : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Vendu'),
                          selected: filter.availability == Availability.sold,
                          onSelected: (selected) {
                            setState(() {
                              filter.availability =
                                  selected ? Availability.sold : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date de publication
                    const Text(
                      'Date de publication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Aujourd\'hui'),
                          selected: filter.publishedAfter?.day ==
                              DateTime.now().day,
                          onSelected: (selected) {
                            setState(() {
                              filter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 1))
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Cette semaine'),
                          selected: filter.publishedAfter?.day ==
                              DateTime.now()
                                  .subtract(const Duration(days: 7))
                                  .day,
                          onSelected: (selected) {
                            setState(() {
                              filter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 7))
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Ce mois'),
                          selected: filter.publishedAfter?.month ==
                              DateTime.now().month,
                          onSelected: (selected) {
                            setState(() {
                              filter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 30))
                                  : null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showResults(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _getFilteredProperties(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé pour "$query"',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final property = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => close(context, property),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageViewerWidget(
                        url: property.images.isNotEmpty
                            ? property.images.first
                            : '',
                        width: 80,
                        height: 80,
                        imageFit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.details,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${property.price.toStringAsFixed(0)}€',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Commencez à taper pour rechercher',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return buildResults(context);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Property> filteredProperties = [];
  String currentSearchQuery = '';
  PropertyFilter currentFilter = PropertyFilter();

  final List<Property> properties = [
    Property(
      images: [],
      title: 'Appartement moderne',
      details: '3 chambres • 2 salles de bain • 120m²',
      price: 350000,
      pricePerMeter: 2916.67,
      rating: 4.8,
      reviews: 12,
      publishedAt: DateTime.now(),
      availability: Availability.available,
      propertyType: PropertyType.apartmentForSale,
      bedrooms: 3,
      surface: 120,
      description: 'Appartement moderne avec vue sur la ville',
      bathrooms: 2,
      location: 'Paris, France',
      id: '1',
      publisher: {
        '_id': 'user1',
        'name': 'John Doe',
        'email': 'john@example.com',
      },
    ),
    Property(
      images: [],
      title: 'Villa de luxe',
      details: '5 chambres • 3 salles de bain • 250m²',
      price: 1200000,
      pricePerMeter: 4800,
      rating: 4.9,
      reviews: 8,
      publishedAt: DateTime.now(),
      availability: Availability.available,
      propertyType: PropertyType.houseForRent,
      bedrooms: 5,
      surface: 250,
      description: 'Villa de luxe avec piscine et jardin',
      bathrooms: 3,
      location: 'Côte d\'Azur, France',
      id: '2',
      publisher: {
        '_id': 'user2',
        'name': 'Jane Smith',
        'email': 'jane@example.com',
      },
    ),
    Property(
      images: [],
      title: 'Loft industriel rénové',
      details: '2 chambres • 2 salles de bain • 100m²',
      price: 280000,
      pricePerMeter: 2800,
      rating: 4.7,
      reviews: 10,
      publishedAt: DateTime.now(),
      availability: Availability.available,
      propertyType: PropertyType.apartmentForSale,
      bedrooms: 2,
      surface: 100,
      description: 'Loft industriel rénové avec vue sur la ville',
      bathrooms: 2,
      location: 'Lyon, France',
      id: '3',
      publisher: {
        '_id': 'user3',
        'name': 'Bob Johnson',
        'email': 'bob@example.com',
      },
    ),
    Property(
      images: [],
      title: 'Maison contemporaine',
      details: '4 chambres • 2 salles de bain • 180m²',
      price: 900000,
      pricePerMeter: 5000,
      rating: 4.9,
      reviews: 15,
      publishedAt: DateTime.now(),
      availability: Availability.available,
      propertyType: PropertyType.houseForRent,
      bedrooms: 4,
      surface: 180,
      description: 'Maison contemporaine avec terrasse et jardin',
      bathrooms: 2,
      location: 'Bordeaux, France',
      id: '4',
      publisher: {
        '_id': 'user4',
        'name': 'Alice Brown',
        'email': 'alice@example.com',
      },
    ),
    Property(
      images: [],
      title: 'Duplex avec vue panoramique',
      details: '3 chambres • 2 salles de bain • 150m²',
      price: 420000,
      pricePerMeter: 2800,
      rating: 4.6,
      reviews: 12,
      publishedAt: DateTime.now(),
      availability: Availability.available,
      propertyType: PropertyType.apartmentForSale,
      bedrooms: 3,
      surface: 150,
      description: 'Duplex avec vue panoramique sur la ville',
      bathrooms: 2,
      location: 'Marseille, France',
      id: '5',
      publisher: {
        '_id': 'user5',
        'name': 'Mike Davis',
        'email': 'mike@example.com',
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ListingCubit>().getListings();
    filteredProperties = properties;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties(String query) {
    if (query == currentSearchQuery) return; // Évite les mises à jour inutiles
    currentSearchQuery = query;

    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredProperties = properties;
        } else {
          filteredProperties = properties.where((property) {
            return property.title.toLowerCase().contains(query.toLowerCase()) ||
                property.details.toLowerCase().contains(query.toLowerCase()) ||
                property.price.toString().contains(query);
          }).toList();
        }
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentFilter = PropertyFilter();
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Type de propriété
                    const Text(
                      'Type de bien',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Appartement à vendre'),
                          selected: currentFilter.propertyType ==
                              PropertyType.apartmentForSale,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.propertyType = selected
                                  ? PropertyType.apartmentForSale
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Appartement à louer'),
                          selected: currentFilter.propertyType ==
                              PropertyType.apartmentForRent,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.propertyType = selected
                                  ? PropertyType.apartmentForRent
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Maison à louer'),
                          selected: currentFilter.propertyType ==
                              PropertyType.houseForRent,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.propertyType =
                                  selected ? PropertyType.houseForRent : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Prix
                    const Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              prefixText: '€',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                currentFilter.minPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              prefixText: '€',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                currentFilter.maxPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nombre de chambres
                    const Text(
                      'Nombre de chambres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${index + 1}'),
                            selected: currentFilter.minBedrooms == index + 1,
                            onSelected: (selected) {
                              setState(() {
                                currentFilter.minBedrooms =
                                    selected ? index + 1 : null;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Disponibilité
                    const Text(
                      'Disponibilité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Disponible'),
                          selected: currentFilter.availability ==
                              Availability.available,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.availability =
                                  selected ? Availability.available : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Loué'),
                          selected:
                              currentFilter.availability == Availability.rented,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.availability =
                                  selected ? Availability.rented : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Vendu'),
                          selected:
                              currentFilter.availability == Availability.sold,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.availability =
                                  selected ? Availability.sold : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date de publication
                    const Text(
                      'Date de publication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Aujourd\'hui'),
                          selected: currentFilter.publishedAfter?.day ==
                              DateTime.now().day,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 1))
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Cette semaine'),
                          selected: currentFilter.publishedAfter?.day ==
                              DateTime.now()
                                  .subtract(const Duration(days: 7))
                                  .day,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 7))
                                  : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Ce mois'),
                          selected: currentFilter.publishedAfter?.month ==
                              DateTime.now().month,
                          onSelected: (selected) {
                            setState(() {
                              currentFilter.publishedAfter = selected
                                  ? DateTime.now()
                                      .subtract(const Duration(days: 30))
                                  : null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      filteredProperties = properties
          .where((property) => currentFilter.matches(property))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageViewerWidget(
              url:
                  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=2070',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              imageFit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeText(),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Biens recommandés',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navigation vers la liste complète
                                      },
                                      child: const Text('Voir tout'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 270,
                                child: BlocBuilder<ListingCubit, ListingState>(
                                  builder: (context, state) {
                                    if (state is ListingLoading) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (state is ListingError) {
                                      return Center(
                                          child:
                                              Text('Erreur: ${state.message}'));
                                    }

                                    if (state is ListingSuccess) {
                                      final data = state.data;
                                      print('API Response: $data');

                                      // Vérifier si data['data'] existe et n'est pas null
                                      if (data['data'] == null) {
                                        return const Center(
                                          child:
                                              Text('Aucune donnée disponible'),
                                        );
                                      }

                                      // Convertir les données en liste
                                      List<dynamic> listings;
                                      if (data['data'] is Map) {
                                        listings = [data['data']];
                                      } else {
                                        listings =
                                            List<dynamic>.from(data['data']);
                                      }

                                      // Filtrer les publications pour exclure celles du user connecté
                                      final authState =
                                          context.read<AuthCubit>().state;
                                      if (authState is AuthSuccess) {
                                        final currentUserId =
                                            authState.user?['id'] as String?;
                                        if (currentUserId?.isNotEmpty ??
                                            false) {
                                          listings = listings.where((listing) {
                                            // Vérifier que publisher existe et a un id
                                            if (listing['publisher'] == null)
                                              return true;

                                            final publisherId =
                                                (listing['publisher'] is Map)
                                                    ? listing['publisher']['id']
                                                        ?.toString()
                                                    : null;
                                            return publisherId != currentUserId;
                                          }).toList();
                                        }
                                      }

                                      if (listings.isEmpty) {
                                        return const Center(
                                          child:
                                              Text('Aucune annonce disponible'),
                                        );
                                      }

                                      return ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: listings.length,
                                        itemBuilder: (context, index) {
                                          final listing = listings[index];
                                          print('Current listing: $listing');

                                          // Extraction sûre des données avec vérification de type
                                          Map<String, dynamic> apartment = {};
                                          if (listing['apartmentId'] != null) {
                                            apartment =
                                                listing['apartmentId'] is Map
                                                    ? Map<String, dynamic>.from(
                                                        listing['apartmentId'])
                                                    : {};
                                          }

                                          Map<String, dynamic> building = {};
                                          if (apartment['buildingId'] != null) {
                                            building =
                                                apartment['buildingId'] is Map
                                                    ? Map<String, dynamic>.from(
                                                        apartment['buildingId'])
                                                    : {};
                                          }

                                          Map<String, dynamic> address = {};
                                          if (building['address'] != null) {
                                            address = building['address'] is Map
                                                ? Map<String, dynamic>.from(
                                                    building['address'])
                                                : {};
                                          }

                                          Map<String, dynamic> price = {};
                                          if (listing['price'] != null) {
                                            price = listing['price'] is Map
                                                ? Map<String, dynamic>.from(
                                                    listing['price'])
                                                : {};
                                          }
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PropertyDetailScreen(
                                                    property: Property(
                                                      images: listing['images'] is List
                                                          ? (listing['images'] as List).map((img) => img.toString()).toList()
                                                          : <String>[],
                                                      title: (listing['title'] ?? 'Sans titre').toString(),
                                                      details: '${(apartment['rooms'] ?? listing['rooms'] ?? 0).toString()} chambres • ${(apartment['bathrooms'] ?? listing['bathrooms'] ?? 0).toString()} salle(s) de bain • ${(apartment['surface'] ?? listing['surface'] ?? 0).toString()}m²',
                                                      price: double.parse((price['amount'] ?? 0).toString()),
                                                      pricePerMeter: double.parse((price['amount'] ?? 0).toString()) / double.parse((apartment['surface'] ?? listing['surface'] ?? 1).toString()),
                                                      rating: 4.5,
                                                      reviews: 10,
                                                      publishedAt: DateTime.tryParse((listing['createdAt'] ?? '').toString()) ?? DateTime.now(),
                                                      availability: listing['status'] == 'active' ? Availability.available : Availability.unavailable,
                                                      propertyType: apartment['type'] == 'studio' ? PropertyType.apartmentForRent : PropertyType.houseForRent,
                                                      bedrooms: int.parse((apartment['rooms'] ?? listing['rooms'] ?? 0).toString()),
                                                      surface: double.parse((apartment['surface'] ?? listing['surface'] ?? 0).toString()),
                                                      description: (listing['description'] ?? 'Aucune description disponible').toString(),
                                                      bathrooms: int.parse((apartment['bathrooms'] ?? listing['bathrooms'] ?? 0).toString()),
                                                      location: '${(address['city'] ?? '').toString()}, ${(address['street'] ?? '').toString()}',
                                                      id: (listing['listingId'] ?? '').toString(),
                                                      publisher: {
                                                        '_id': (listing['publisher']?['id'] ?? '').toString(),
                                                        'firstName': (listing['publisher']?['name'] ?? '').toString().split(' ').isNotEmpty ? (listing['publisher']?['name'] ?? '').toString().split(' ')[0] : '',
                                                        'lastName': (listing['publisher']?['name'] ?? '').toString().split(' ').length > 1 ? (listing['publisher']?['name'] ?? '').toString().split(' ')[1] : '',
                                                        'phone': (listing['publisher']?['phone'] ?? '').toString(),
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 220,
                                              margin: const EdgeInsets.only(
                                                  right: 16),
                                              child: Card(
                                                color: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                      color: Colors.grey
                                                          .withOpacity(0.5),
                                                      width: 1),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        ImageViewerWidget(
                                                          url: (listing['images']
                                                                          as List?)
                                                                      ?.isNotEmpty ==
                                                                  true
                                                              ? listing[
                                                                  'images'][0]
                                                              : '',
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          height: 140,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                        // ClipRRect(
                                                        //   borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                        //   child: Image.network(
                                                        //     'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=2070',
                                                        //     height: 120,
                                                        //     width: 220,
                                                        //     fit: BoxFit.cover,
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            listing['title']
                                                                    ?.toString() ??
                                                                'Sans titre',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            listing['description']
                                                                    ?.toString() ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            'Prix: ${price['amount']?.toString() ?? '0'} ${price['currency']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }

                                    // Return par défaut
                                    return const Center(
                                      child: Text('Aucune donnée disponible'),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 240)
                            ],
                          ),
                        ),
                        const SizedBox(height: 240),

                        // ... Reste du contenu
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                left: BorderSide(
                  color: AppColors.buttonColor,
                  width: 8,
                ),
                right: BorderSide(
                  color: AppColors.buttonColor,
                  width: 2,
                ),
                top: BorderSide(
                  color: AppColors.buttonColor,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: AppColors.buttonColor,
                  width: 1,
                ),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.buttonColor),
                SizedBox(width: 4),
                Text('Kinshasa',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess && 
                  state.user != null && 
                  state.user!['profileImage'] != null) {
                // Display profile image if available
                return CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.buttonColor,
                    backgroundImage: NetworkImage(state.user!['profileImage']),
                    child: IconButton(
                      icon: const Icon(Icons.person, color: Colors.transparent),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingScreen()));
                      },
                    ),
                  ),
                );
              } else {
                // Show default person icon if no profile image
                return CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.buttonColor,
                    child: IconButton(
                      icon: const Icon(Icons.person, color: AppColors.buttonColor),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingScreen()));
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Text(
        'Trouvez votre\nprochain chez-vous',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final selectedProperty = await showSearch<Property?>(
                  context: context,
                  delegate: PropertySearchDelegate(
                    properties,
                    (query) {},
                    currentFilter, // Passer le filtre actuel
                  ),
                );
                if (selectedProperty != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PropertyDetailScreen(property: selectedProperty),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: const Border(
                    left: BorderSide(
                      color: AppColors.buttonColor,
                      width: 7,
                    ),
                    right: BorderSide(
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                    top: BorderSide(
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                  ),

                  // color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.buttonColor),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rechercher un bien',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Type • Prix • Surface',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 75,
            width: 70,
            decoration: BoxDecoration(
              // color: Colors.black.withOpacity(0.3),
              border: const Border(
                left: BorderSide(
                  color: AppColors.buttonColor,
                  width: 2,
                ),
                right: BorderSide(
                  color: AppColors.buttonColor,
                  width: 2,
                ),
                top: BorderSide(
                  color: AppColors.buttonColor,
                  width: 2,
                ),
                bottom: BorderSide(
                  color: AppColors.buttonColor,
                  width: 2,
                ),
              ),
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune,
                color: AppColors.buttonColor,
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text(
              'Biens recommandés',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filteredProperties.length,
              itemBuilder: (context, index) {
                final property = filteredProperties[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildPropertyCard(context, property),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Découvrez nos quartiers',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDiscoverSection(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(property: property),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: ImageViewerWidget(
                  url: property.images.isNotEmpty ? property.images.first : '',
                  width: double.infinity,
                  height: 140,
                  imageFit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FutureBuilder<bool>(
                  future: FavoritesRepository.isFavorite(property.id),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () async {
                          await FavoritesRepository.toggleFavorite(
                              property.toJson());
                          setState(() {});
                          favoritesUpdateStream.add(null);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite
                                    ? 'Retiré des favoris'
                                    : 'Ajouté aux favoris'),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                backgroundColor:
                                    isFavorite ? Colors.grey : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16),
                        Text('${property.rating} (${property.reviews})'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  property.details,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '${property.price.toInt()} 000€ ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '• '),
                      TextSpan(text: '${property.pricePerMeter.toInt()}€/m²'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSection() {
    final List<String> discoverImages = [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?q=80&w=2074',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=2070',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=2029',
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: discoverImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ImageViewerWidget(
                url: discoverImages[index],
                width: 160,
                height: 120,
                imageFit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildListingCard(Map<String, dynamic> listing) {
  try {
    final apartment = listing['apartmentId'] as Map<String, dynamic>;
    final building = apartment['buildingId'] as Map<String, dynamic>;
    final address = building['address'] as Map<String, dynamic>;
    final publisher = listing['publisher'] as Map<String, dynamic>;
    final listingPrice = listing['price'] as Map<String, dynamic>;
    final apartmentPrice = apartment['price'] as Map<String, dynamic>;
    final features = apartment['features'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              listing['title']?.toString() ?? 'Sans titre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(building['name']?.toString() ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: listing['status'] == 'active'
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                listing['status'] == 'active' ? 'Disponible' : 'Non disponible',
                style: TextStyle(
                  color: listing['status'] == 'active'
                      ? Colors.green
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type et caractéristiques
                Row(
                  children: [
                    Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${apartment['type']?.toString() ?? ''} • ${apartment['rooms']?.toString() ?? '0'} chambres • ${apartment['surface']?.toString() ?? '0'} m²',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Adresse
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                        '${address['city'] ?? ''}, ${address['street'] ?? ''}'),
                  ],
                ),
                const SizedBox(height: 8),

                // Prix
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${listingPrice['amount']?.toString() ?? '0'} ${listingPrice['currency']?.toString() ?? 'USD'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                        ' / ${apartmentPrice['paymentFrequency']?.toString() ?? 'mois'}'),
                    if (listingPrice['negotiable'] == true)
                      Text(' • Négociable',
                          style: TextStyle(color: Colors.grey[600])),
                  ],
                ),

                if (listing['description']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    listing['description'].toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (features != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (features['furnished'] == true)
                    _buildFeatureChip('Meublé'),
                  if (features['airConditioning'] == true)
                    _buildFeatureChip('Climatisation'),
                  if (features['balcony'] == true) _buildFeatureChip('Balcon'),
                  if (features['internet'] == true)
                    _buildFeatureChip('Internet'),
                  if (features['parking'] == true) _buildFeatureChip('Parking'),
                  if (features['securitySystem'] == true)
                    _buildFeatureChip('Sécurité'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        '${publisher['firstName']?.toString() ?? ''} ${publisher['lastName']?.toString() ?? ''}'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, size: 16),
                    const SizedBox(width: 4),
                    Text('${listing['views']?.toString() ?? '0'} vues'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    print('Error building listing card: $e');
    return const SizedBox();
  }
}

Widget _buildFeatureChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 12,
      ),
    ),
  );
}
