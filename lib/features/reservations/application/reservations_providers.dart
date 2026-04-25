import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reservations_api.dart';
import '../domain/reservation.dart';

final driverRequestsProvider = FutureProvider<List<Reservation>>(
  (ref) => ref.read(reservationsApiProvider).getDriverPendingRequests(),
);

final driverConfirmedProvider = FutureProvider<List<Reservation>>(
  (ref) => ref.read(reservationsApiProvider).getDriverConfirmed(),
);

final passengerRequestsProvider = FutureProvider<List<Reservation>>(
  (ref) => ref.read(reservationsApiProvider).getPassengerRequests(),
);

final passengerConfirmedProvider = FutureProvider<List<Reservation>>(
  (ref) => ref.read(reservationsApiProvider).getPassengerConfirmed(),
);

final passengerHistoryProvider = FutureProvider<List<Reservation>>(
  (ref) => ref.read(reservationsApiProvider).getPassengerHistory(),
);
