class Property {
  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final double price;
  final int guests;
  final int bedrooms;
  final int beds;
  final int bathrooms;
  final double rating;
  final int reviews;
  final String type; // 'rent' or 'sale'
  final bool isFavorite;
  final Map<String, dynamic> publisher;

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.guests,
    required this.bedrooms,
    required this.beds,
    required this.bathrooms,
    required this.rating,
    required this.reviews,
    required this.type,
    this.isFavorite = false,
    required this.publisher,
  });
}
