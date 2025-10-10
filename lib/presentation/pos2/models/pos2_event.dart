class POS2Event {
  final int id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final String? image;

  POS2Event({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    required this.active,
    this.image,
  });

  factory POS2Event.fromJson(Map<String, dynamic> json) {
    return POS2Event(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date']) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.tryParse(json['end_date']) 
          : null,
      active: json['active'] == 1 || json['active'] == true,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'active': active ? 1 : 0,
      'image': image,
    };
  }

  @override
  String toString() {
    return 'POS2Event{id: $id, name: $name, active: $active}';
  }
}