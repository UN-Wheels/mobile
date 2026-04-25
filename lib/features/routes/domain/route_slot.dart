class RouteSlot {
  const RouteSlot({
    required this.date,
    required this.totalSeats,
    required this.usedSeats,
    required this.availableSeats,
  });

  final DateTime date;
  final int totalSeats;
  final int usedSeats;
  final int availableSeats;

  bool get hasAvailability => availableSeats > 0;

  factory RouteSlot.fromJson(Map<String, dynamic> json) => RouteSlot(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 0,
        usedSeats: (json['usedSeats'] as num?)?.toInt() ?? 0,
        availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      );
}
