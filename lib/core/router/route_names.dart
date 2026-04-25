abstract final class RouteNames {
  // Auth (sin bottom nav)
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Dashboard shell (bottom nav)
  static const String dashboard = '/dashboard';
  static const String search = '/search';
  static const String bookings = '/bookings';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // Full-screen (sobre el bottom nav)
  static const String routeDetail = '/routes/:id';
  static const String publishRoute = '/publish';
  static const String myRoutes = '/my-routes';
  static const String chatDetail = '/chat/:conversationId';

  // Helpers para navegación con parámetros
  static String routeDetailOf(String id) => '/routes/$id';
  static String chatDetailOf(String conversationId) => '/chat/$conversationId';
}
