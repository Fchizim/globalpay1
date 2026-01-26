class Listing {
  final String title;
  final String price;
  final String description;
  final String location;
  final String category;
  final String condition;
  final List<String> images;

  Listing({
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    required this.category,
    required this.condition,
    required this.images,
  });

  // For backend later
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'price': price,
    'description': description,
    'location': location,
    'category': category,
    'condition': condition,
    'images': images,
  };
}
