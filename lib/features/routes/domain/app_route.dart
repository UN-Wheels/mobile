class RouteLocation {
  const RouteLocation({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;

  factory RouteLocation.fromJson(Map<String, dynamic> json) => RouteLocation(
        name: (json['name'] ?? json['address'] ?? '').toString(),
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng};
}

class DriverInfo {
  const DriverInfo({required this.id, required this.name, this.email, this.profilePicture});

  final String id;
  final String name;
  final String? email;
  final String? profilePicture;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get displayName => name.isNotEmpty ? name : (email ?? id);

  factory DriverInfo.fromJson(Map<String, dynamic> json) => DriverInfo(
        id: (json['id'] ?? json['_id'] ?? json['sub'] ?? '').toString(),
        name: (json['name'] ?? json['fullName'] ?? json['full_name'] ?? '').toString(),
        email: json['email']?.toString(),
        profilePicture:
            (json['profile_picture'] ?? json['profilePicture'])?.toString(),
      );
}

class VehicleInfo {
  const VehicleInfo({
    required this.id,
    required this.brand,
    required this.model,
    required this.color,
    required this.plateNumber,
  });

  final String id;
  final String brand;
  final String model;
  final String color;
  final String plateNumber;

  String get summary => '$brand $model · $plateNumber';

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        brand: (json['brand'] ?? '').toString(),
        model: (json['model'] ?? '').toString(),
        color: (json['color'] ?? '').toString(),
        plateNumber:
            (json['plateNumber'] ?? json['plate_number'] ?? json['plate'] ?? '').toString(),
      );
}

class AppRoute {
  const AppRoute({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.pricePerSeat,
    required this.status,
    required this.createdAt,
    this.vehicleId,
    this.driver,
    this.vehicle,
  });

  final String id;
  final String driverId;
  final String? vehicleId;
  final RouteLocation origin;
  final RouteLocation destination;
  final DateTime departureTime;
  final double pricePerSeat;
  final String status; // ACTIVE | INACTIVE | IN_PROGRESS | COMPLETED
  final DateTime createdAt;
  final DriverInfo? driver;
  final VehicleInfo? vehicle;

  bool get isActive => status == 'ACTIVE';
  String get description => '${origin.name} → ${destination.name}';

  factory AppRoute.fromJson(Map<String, dynamic> json) => AppRoute(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        // Gateway replaces driverId with driver:{...}; fall back to driver.email
        driverId: (json['driverId'] ??
                (json['driver'] is Map<String, dynamic>
                    ? (json['driver'] as Map<String, dynamic>)['email']
                    : null) ??
                '')
            .toString(),
        vehicleId: json['vehicleId']?.toString(),
        origin: RouteLocation.fromJson(
          json['origin'] as Map<String, dynamic>? ?? {'name': '', 'lat': 0, 'lng': 0},
        ),
        destination: RouteLocation.fromJson(
          json['destination'] as Map<String, dynamic>? ?? {'name': '', 'lat': 0, 'lng': 0},
        ),
        departureTime:
            DateTime.tryParse(json['departureTime']?.toString() ?? '') ?? DateTime.now(),
        pricePerSeat:
            ((json['pricePerSeat'] ?? json['price']) as num?)?.toDouble() ?? 0.0,
        status: (json['status'] ?? 'ACTIVE').toString(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        driver: json['driver'] is Map<String, dynamic>
            ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
            : null,
        vehicle: json['vehicle'] is Map<String, dynamic>
            ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
            : null,
      );
}
