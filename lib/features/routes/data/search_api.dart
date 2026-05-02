import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/app_route.dart';

// ─── Parámetros de búsqueda ───────────────────────────────────────────────────

class SearchRoutesParams {
  const SearchRoutesParams({
    this.originName,
    this.destName,
    this.originLat,
    this.originLng,
    this.originRadius,
    this.destLat,
    this.destLng,
    this.destRadius,
    this.date,
    this.timeFrom,
    this.timeTo,
    this.maxPrice,
    this.page = 1,
    this.limit = 20,
  });

  final String? originName;
  final String? destName;
  final double? originLat;
  final double? originLng;
  final double? originRadius;
  final double? destLat;
  final double? destLng;
  final double? destRadius;
  final DateTime? date;      // filtra por día
  final String? timeFrom;   // HH:MM
  final String? timeTo;     // HH:MM
  final double? maxPrice;
  final int page;
  final int limit;

  bool get isEmpty =>
      originName == null &&
      destName == null &&
      originLat == null &&
      destLat == null &&
      date == null &&
      timeFrom == null &&
      timeTo == null &&
      maxPrice == null;

  Map<String, dynamic> toQueryParams() {
    final p = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (originName != null && originName!.isNotEmpty) p['origin_name'] = originName;
    if (destName != null && destName!.isNotEmpty)     p['dest_name']   = destName;
    if (originLat != null) p['origin_lat']    = originLat;
    if (originLng != null) p['origin_lng']    = originLng;
    if (originRadius != null) p['origin_radius'] = originRadius;
    if (destLat != null)   p['dest_lat']      = destLat;
    if (destLng != null)   p['dest_lng']      = destLng;
    if (destRadius != null)  p['dest_radius']   = destRadius;
    if (date != null) {
      p['date'] =
          '${date!.year.toString().padLeft(4, '0')}-'
          '${date!.month.toString().padLeft(2, '0')}-'
          '${date!.day.toString().padLeft(2, '0')}';
    }
    if (timeFrom != null) p['time_from'] = timeFrom;
    if (timeTo != null)   p['time_to']   = timeTo;
    if (maxPrice != null) p['max_price'] = maxPrice;
    return p;
  }
}

// ─── Respuesta del servicio ───────────────────────────────────────────────────

class SearchRoutesResult {
  const SearchRoutesResult({
    required this.routes,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<AppRoute> routes;
  final int total;
  final int page;
  final int pages;
}

// ─── Mapper item plano → AppRoute ─────────────────────────────────────────────

AppRoute _mapSearchItem(Map<String, dynamic> json) => AppRoute(
      id: (json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      origin: RouteLocation(
        name: (json['originName'] ?? '').toString(),
        lat: (json['originLat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['originLng'] as num?)?.toDouble() ?? 0.0,
      ),
      destination: RouteLocation(
        name: (json['destName'] ?? '').toString(),
        lat: (json['destLat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['destLng'] as num?)?.toDouble() ?? 0.0,
      ),
      departureTime:
          DateTime.tryParse(json['departureTime']?.toString() ?? '') ??
              DateTime.now(),
      pricePerSeat:
          ((json['pricePerSeat'] ?? json['price']) as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? 'ACTIVE').toString(),
      createdAt: DateTime.now(),
    );

// ─── API ─────────────────────────────────────────────────────────────────────

class SearchApi {
  const SearchApi(this._dio);

  final Dio _dio;

  /// GET /search/routes — public, no JWT required.
  Future<SearchRoutesResult> searchRoutes(SearchRoutesParams params) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/search/routes',
        queryParameters: params.toQueryParams(),
      );

      final data = res.data;
      final items = (data?['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapSearchItem)
          .toList();

      return SearchRoutesResult(
        routes: items,
        total:  (data?['total']  as num?)?.toInt() ?? items.length,
        page:   (data?['page']   as num?)?.toInt() ?? 1,
        pages:  (data?['pages']  as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final searchApiProvider = Provider<SearchApi>(
  (ref) => SearchApi(ref.read(dioProvider)),
);
