import '../../routes/domain/app_route.dart';

class ReservationRouteInfo {
  const ReservationRouteInfo({
    required this.id,
    required this.origin,
    required this.destination,
    required this.pricePerSeat,
    this.driver,
  });

  final String id;
  final RouteLocation origin;
  final RouteLocation destination;
  final double pricePerSeat;
  final DriverInfo? driver;

  factory ReservationRouteInfo.fromJson(Map<String, dynamic> json) {
    final raw = json;
    return ReservationRouteInfo(
      id: (raw['_id'] ?? raw['id'] ?? '').toString(),
      origin: RouteLocation.fromJson(raw['origin'] as Map<String, dynamic>),
      destination: RouteLocation.fromJson(raw['destination'] as Map<String, dynamic>),
      pricePerSeat: ((raw['pricePerSeat'] ?? raw['price'] ?? 0) as num).toDouble(),
      driver: raw['driver'] != null
          ? DriverInfo.fromJson(raw['driver'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PassengerInfo {
  const PassengerInfo({required this.email, required this.name, this.lastName});

  final String email;
  final String name;
  final String? lastName;

  String get displayName {
    final last = lastName;
    return last != null && last.isNotEmpty ? '$name $last' : name;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  factory PassengerInfo.fromJson(Map<String, dynamic> json) => PassengerInfo(
        email: (json['email'] ?? '').toString(),
        name: (json['name'] ?? json['nombre'] ?? '').toString(),
        lastName: json['lastName'] as String? ?? json['apellido'] as String?,
      );
}

class Reservation {
  const Reservation({
    required this.id,
    required this.routeId,
    required this.passengerId,
    required this.travelDate,
    required this.status,
    required this.createdAt,
    this.route,
    this.passenger,
  });

  final String id;
  final String routeId;
  final String passengerId;
  final DateTime travelDate;
  final String status;
  final DateTime createdAt;
  final ReservationRouteInfo? route;
  final PassengerInfo? passenger;

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';

  factory Reservation.fromJson(Map<String, dynamic> json) {
    ReservationRouteInfo? route;
    String routeId;
    final rawRoute = json['routeId'];
    if (rawRoute is Map<String, dynamic>) {
      route = ReservationRouteInfo.fromJson(rawRoute);
      routeId = route.id;
    } else {
      routeId = (rawRoute ?? '').toString();
    }

    PassengerInfo? passenger;
    final rawPassenger = json['passenger'];
    if (rawPassenger is Map<String, dynamic>) {
      passenger = PassengerInfo.fromJson(rawPassenger);
    }

    return Reservation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      routeId: routeId,
      passengerId: (json['passengerId'] ?? '').toString(),
      travelDate: DateTime.parse(json['travelDate'] as String),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      route: route,
      passenger: passenger,
    );
  }
}
