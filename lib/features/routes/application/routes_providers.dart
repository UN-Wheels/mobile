import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/routes_api.dart';
import '../domain/app_route.dart';
import '../domain/route_slot.dart';

final availableRoutesProvider = FutureProvider<List<AppRoute>>((ref) {
  return ref.read(routesApiProvider).getAvailableRoutes();
});

final myRoutesProvider = FutureProvider<List<AppRoute>>((ref) {
  return ref.read(routesApiProvider).getMyRoutes();
});

final routeDetailProvider = FutureProvider.family<AppRoute, String>((ref, id) {
  return ref.read(routesApiProvider).getRoute(id);
});

final routeSlotsProvider = FutureProvider.family<List<RouteSlot>, String>((ref, id) {
  final from = DateTime.now();
  final to = from.add(const Duration(days: 90));
  return ref.read(routesApiProvider).getSlots(id, from: from, to: to);
});
