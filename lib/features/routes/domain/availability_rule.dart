sealed class AvailabilityRule {
  const AvailabilityRule({required this.id, required this.routeId});

  final String id;
  final String routeId;

  factory AvailabilityRule.fromJson(Map<String, dynamic> json) =>
      switch (json['kind'] as String?) {
        'WEEKLY_RECURRENCE' => WeeklyRecurrenceRule.fromJson(json),
        _ => SpecificDatesRule.fromJson(json),
      };
}

class SpecificDateEntry {
  const SpecificDateEntry({required this.date, required this.seats});

  final DateTime date;
  final int seats;

  factory SpecificDateEntry.fromJson(Map<String, dynamic> json) => SpecificDateEntry(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        seats: (json['seats'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toUtc().toIso8601String(),
        'seats': seats,
      };
}

class SpecificDatesRule extends AvailabilityRule {
  const SpecificDatesRule({
    required super.id,
    required super.routeId,
    required this.entries,
  });

  final List<SpecificDateEntry> entries;

  factory SpecificDatesRule.fromJson(Map<String, dynamic> json) {
    final raw = (json['specificEntries'] ?? json['entries']) as List<dynamic>? ?? [];
    return SpecificDatesRule(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      routeId: (json['routeId'] ?? '').toString(),
      entries: raw.whereType<Map<String, dynamic>>().map(SpecificDateEntry.fromJson).toList(),
    );
  }
}

class WeeklyRecurrenceRule extends AvailabilityRule {
  const WeeklyRecurrenceRule({
    required super.id,
    required super.routeId,
    required this.weekdays,
    required this.rangeStart,
    required this.rangeEnd,
    required this.seatsPerOccurrence,
  });

  final List<int> weekdays; // 1=lun … 7=dom
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int seatsPerOccurrence;

  static const _dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String get weekdaysLabel =>
      weekdays.map((d) => d >= 1 && d <= 7 ? _dayNames[d] : '?').join(', ');

  factory WeeklyRecurrenceRule.fromJson(Map<String, dynamic> json) => WeeklyRecurrenceRule(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        routeId: (json['routeId'] ?? '').toString(),
        weekdays: (json['weekdays'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        rangeStart:
            DateTime.tryParse(json['rangeStart']?.toString() ?? '') ?? DateTime.now(),
        rangeEnd:
            DateTime.tryParse(json['rangeEnd']?.toString() ?? '') ?? DateTime.now(),
        seatsPerOccurrence: (json['seatsPerOccurrence'] as num?)?.toInt() ?? 1,
      );
}
