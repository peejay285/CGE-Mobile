class Event {
  final int id;
  final String title;
  final String date;
  final String time;
  final String type; // Party, Special, Demo, Package
  final String? description;
  final String? location;
  final bool isFree;
  final int? price;
  final int? capacity;
  final String? imageUrl;
  final String createdAt;
  final int? registeredCount;
  final bool? userRegistered;

  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    this.description,
    this.location,
    this.isFree = true,
    this.price,
    this.capacity,
    this.imageUrl,
    required this.createdAt,
    this.registeredCount,
    this.userRegistered,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as int,
        title: json['title'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        type: json['type'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        isFree: json['is_free'] as bool? ?? true,
        price: json['price'] as int?,
        capacity: json['capacity'] as int?,
        imageUrl: json['image_url'] as String?,
        createdAt: json['created_at'] as String,
      );
}
