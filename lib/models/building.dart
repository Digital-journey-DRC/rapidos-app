class Building {
  final String name;
  final Address address;
  final String description;
  final List<String> features;
  final int totalApartments;
  final int availableApartments;
  final String status;
  final int constructionYear;
  final String? id;
  final Map<String, dynamic>? owner;
  final List<String>? images;

  Building({
    required this.name,
    required this.address,
    required this.description,
    required this.features,
    required this.totalApartments,
    required this.availableApartments,
    required this.status,
    required this.constructionYear,
    this.id,
    this.owner,
    this.images,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['_id'],
      name: json['name'],
      address: Address.fromJson(json['address']),
      description: json['description'],
      features: List<String>.from(json['features']),
      totalApartments: json['totalApartments'],
      availableApartments: json['availableApartments'],
      status: json['status'],
      constructionYear: json['constructionYear'],
      owner: json['owner'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address.toJson(),
      'description': description,
      'features': features,
      'totalApartments': totalApartments,
      'availableApartments': availableApartments,
      'status': status,
      'constructionYear': constructionYear,
      'images': images,
    };
  }
}

class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }
}
