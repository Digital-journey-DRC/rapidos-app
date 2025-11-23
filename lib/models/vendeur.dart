class Vendeur {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? userStatus;
  final VendeurProfil? profil;
  final Media? media;
  final List<HoraireOuverture>? horairesOuverture;
  final List<dynamic>? products;
  final int? totalProducts;

  Vendeur({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.userStatus,
    this.profil,
    this.media,
    this.horairesOuverture,
    this.products,
    this.totalProducts,
  });

  String get fullName => '$firstName $lastName'.trim();
  String? get profileImageUrl => profil?.media?.mediaUrl ?? media?.mediaUrl;

  factory Vendeur.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    List<HoraireOuverture>? parseHoraires(dynamic horairesJson) {
      if (horairesJson == null) return null;
      if (horairesJson is List) {
        return horairesJson
            .map((h) => HoraireOuverture.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return Vendeur(
      id: parseToInt(json['id'], 0),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userStatus: json['userStatus']?.toString(),
      profil: json['profil'] != null
          ? VendeurProfil.fromJson(json['profil'] as Map<String, dynamic>)
          : null,
      media: json['media'] != null
          ? Media.fromJson(json['media'] as Map<String, dynamic>)
          : null,
      horairesOuverture: parseHoraires(json['horairesOuverture']),
      products: json['products'],
      totalProducts: json['totalProducts'] != null
          ? parseToInt(json['totalProducts'], 0)
          : null,
    );
  }

  /// Crée un Vendeur simplifié depuis un objet vendeur dans un produit
  factory Vendeur.fromProductJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return Vendeur(
      id: parseToInt(json['id'], 0),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profil: json['profil'] != null
          ? VendeurProfil.fromJson(json['profil'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VendeurProfil {
  final int id;
  final Media? media;

  VendeurProfil({
    required this.id,
    this.media,
  });

  factory VendeurProfil.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return VendeurProfil(
      id: parseToInt(json['id'], 0),
      media: json['media'] != null
          ? Media.fromJson(json['media'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HoraireOuverture {
  final int id;
  final String jour;
  final String? heureOuverture;
  final String? heureFermeture;
  final bool estOuvert;

  HoraireOuverture({
    required this.id,
    required this.jour,
    this.heureOuverture,
    this.heureFermeture,
    required this.estOuvert,
  });

  factory HoraireOuverture.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return HoraireOuverture(
      id: parseToInt(json['id'], 0),
      jour: json['jour']?.toString() ?? '',
      heureOuverture: json['heureOuverture']?.toString(),
      heureFermeture: json['heureFermeture']?.toString(),
      estOuvert: json['estOuvert'] == true,
    );
  }
}

class Media {
  final int id;
  final String mediaUrl;
  final String mediaType;
  final String createdAt;
  final String updatedAt;
  final int? productId;

  Media({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.updatedAt,
    this.productId,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return Media(
      id: parseToInt(json['id'], 0),
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      productId: json['productId'] != null ? parseToInt(json['productId'], 0) : null,
    );
  }
}

