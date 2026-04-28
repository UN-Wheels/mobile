class Vehicle {
  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.brand,
    required this.model,
    required this.color,
    this.year,
  });

  final String id;
  final String plate;
  final String type;
  final String brand;
  final String model;
  final String color;
  final int? year;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        plate: (json['plate'] ?? json['license_plate'] ?? json['licensePlate'] ?? '').toString(),
        type: (json['vehicle_type'] ?? json['type'] ?? json['vehicleType'] ?? '').toString(),
        brand: (json['brand'] ?? '').toString(),
        model: (json['model'] ?? '').toString(),
        color: (json['color'] ?? '').toString(),
        year: (json['year'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'plate': plate,
        'type': type,
        'brand': brand,
        'model': model,
        'color': color,
        if (year != null) 'year': year,
      };

  String get displayName => '$brand $model ($plate)';
}
