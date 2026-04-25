import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

class DashboardData {
  const DashboardData({
    required this.upcomingTrips,
    required this.myRoutes,
  });

  final List<DashboardReservation> upcomingTrips;
  final List<DashboardRoute> myRoutes;
}

class DashboardReservation {
  const DashboardReservation({
    required this.id,
    required this.routeId,
    required this.routeDescription,
    required this.travelDate,
  });

  final String id;
  final String routeId;
  final String routeDescription;
  final String travelDate;

  factory DashboardReservation.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>?;
    final origin = route?['origin'] as String? ?? '';
    final destination = route?['destination'] as String? ?? '';
    return DashboardReservation(
      id: json['id']?.toString() ?? '',
      routeId: (json['routeId'] ?? json['route_id'] ?? route?['id'])
              ?.toString() ??
          '',
      routeDescription: origin.isNotEmpty && destination.isNotEmpty
          ? '$origin → $destination'
          : 'Ruta',
      travelDate: (json['travelDate'] ?? json['travel_date'] ?? '').toString(),
    );
  }
}

class DashboardRoute {
  const DashboardRoute({
    required this.id,
    required this.description,
    required this.pricePerSeat,
    required this.availableSeats,
    required this.status,
  });

  final String id;
  final String description;
  final double pricePerSeat;
  final int availableSeats;
  final String status;

  factory DashboardRoute.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as String? ?? '';
    final destination = json['destination'] as String? ?? '';
    return DashboardRoute(
      id: json['id']?.toString() ?? '',
      description: origin.isNotEmpty && destination.isNotEmpty
          ? '$origin → $destination'
          : 'Ruta',
      pricePerSeat:
          ((json['pricePerSeat'] ?? json['price_per_seat']) as num?)
              ?.toDouble() ??
          0,
      availableSeats:
          (json['availableSeats'] ?? json['available_seats']) as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

final dashboardControllerProvider =
    FutureProvider<DashboardData>((ref) async {
  final dio = ref.read(dioProvider);

  try {
    final results = await Future.wait([
      dio.get<List<dynamic>>('/routes/reservations/me/passenger/confirmed'),
      dio.get<List<dynamic>>('/routes/routes/me'),
    ]);

    final reservations = (results[0].data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DashboardReservation.fromJson)
        .toList();

    final routes = (results[1].data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DashboardRoute.fromJson)
        .toList();

    return DashboardData(upcomingTrips: reservations, myRoutes: routes);
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
});
