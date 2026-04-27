import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/application/profile_providers.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/add_vehicle_sheet.dart';
import '../data/routes_api.dart';
import 'location_picker_page.dart';

enum _AvailKind { none, specificDate, weekly }

class PublishRoutePage extends ConsumerStatefulWidget {
  const PublishRoutePage({super.key});

  @override
  ConsumerState<PublishRoutePage> createState() => _PublishRoutePageState();
}

class _PublishRoutePageState extends ConsumerState<PublishRoutePage> {
  int _step = 0;
  bool _submitting = false;

  // Step 0 — origin & destination
  LocationPickerResult? _origin;
  LocationPickerResult? _destination;

  // Step 1 — schedule & price
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  final _priceCtrl = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  // Step 2 — vehicle (optional)
  Vehicle? _selectedVehicle;

  // Step 3 — availability
  _AvailKind _availKind = _AvailKind.none;

  // Specific date option
  DateTime? _specificDate;
  final _specificSeatsCtrl = TextEditingController(text: '1');

  // Weekly recurrence option
  final List<bool> _weekdays = List.filled(7, false);
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 90));
  final _weeklySeatsCtrl = TextEditingController(text: '2');

  static const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void dispose() {
    _priceCtrl.dispose();
    _specificSeatsCtrl.dispose();
    _weeklySeatsCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (_step == 0 && !_validateStep0()) return;
    if (_step == 1 && !_validateStep1()) return;
    if (_step < 3) {
      if (_step == 2) {
        // Pre-fill specific date with departure date when entering step 3
        _specificDate ??= _departureDate;
      }
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  bool _validateStep0() {
    if (_origin == null) {
      _showError('Selecciona el punto de origen en el mapa.');
      return false;
    }
    if (_destination == null) {
      _showError('Selecciona el punto de destino en el mapa.');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (!(_step1Key.currentState?.validate() ?? false)) return false;
    if (_departureDate == null) {
      _showError('Selecciona la fecha de salida.');
      return false;
    }
    if (_departureTime == null) {
      _showError('Selecciona la hora de salida.');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dt = _departureDate!;
      final t = _departureTime!;
      final departureDt =
          DateTime(dt.year, dt.month, dt.day, t.hour, t.minute);

      final routeData = <String, dynamic>{
        'origin': {
          'name': _origin!.name,
          'lat': _origin!.lat,
          'lng': _origin!.lng,
        },
        'destination': {
          'name': _destination!.name,
          'lat': _destination!.lat,
          'lng': _destination!.lng,
        },
        'departureTime': departureDt.toUtc().toIso8601String(),
        'pricePerSeat': double.parse(_priceCtrl.text.trim()),
        'status': 'ACTIVE',
        if (_selectedVehicle != null) 'vehicleId': _selectedVehicle!.id,
      };

      final created = await ref.read(routesApiProvider).createRoute(routeData);

      if (_availKind == _AvailKind.specificDate) {
        final date = _specificDate ?? _departureDate!;
        final seats = int.tryParse(_specificSeatsCtrl.text.trim()) ?? 1;
        if (seats < 1) {
          _showError('Ingresa un número válido de cupos (mínimo 1).');
          setState(() => _submitting = false);
          return;
        }
        await ref.read(routesApiProvider).addAvailabilityRule(
          created.id,
          {
            'kind': 'SPECIFIC_DATES',
            'specificEntries': [
              {
                'date': DateTime(date.year, date.month, date.day)
                    .toUtc()
                    .toIso8601String(),
                'seats': seats,
              }
            ],
          },
        );
      } else if (_availKind == _AvailKind.weekly &&
          _weekdays.any((d) => d)) {
        final seats = int.tryParse(_weeklySeatsCtrl.text.trim());
        if (seats == null || seats < 1) {
          _showError('Ingresa un número válido de cupos por día (mínimo 1).');
          setState(() => _submitting = false);
          return;
        }
        final selectedDays = [
          for (int i = 0; i < _weekdays.length; i++) if (_weekdays[i]) i + 1,
        ];
        await ref.read(routesApiProvider).addAvailabilityRule(
          created.id,
          {
            'kind': 'WEEKLY_RECURRENCE',
            'weekdays': selectedDays,
            'rangeStart': _rangeStart.toUtc().toIso8601String(),
            'rangeEnd': _rangeEnd.toUtc().toIso8601String(),
            'seatsPerOccurrence': seats,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ruta publicada exitosamente!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement(RouteNames.myRoutes);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickLocation({required bool isOrigin}) async {
    final current = isOrigin ? _origin : _destination;
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: isOrigin ? 'Seleccionar origen' : 'Seleccionar destino',
          initialName: current?.name,
          initialLat: current?.lat,
          initialLng: current?.lng,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isOrigin) {
        _origin = result;
      } else {
        _destination = result;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _departureDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) setState(() => _departureTime = picked);
  }

  Future<void> _pickSpecificDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _specificDate = picked);
  }

  Future<void> _pickRangeStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _rangeStart = picked);
  }

  Future<void> _pickRangeEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd,
      firstDate: _rangeStart.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _rangeEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Publicar ruta')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _submitting ? null : _continue,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _submitting ? null : details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _submitting && _step == 3
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(_step == 3 ? 'Publicar' : 'Continuar'),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Atrás'),
                ),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Ruta'),
            subtitle: const Text('Origen y destino'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: _buildStep0(),
          ),
          Step(
            title: const Text('Horario y precio'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _buildStep1(),
          ),
          Step(
            title: const Text('Vehículo'),
            subtitle: const Text('Opcional'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: _buildStep2(),
          ),
          Step(
            title: const Text('Disponibilidad'),
            subtitle: const Text('Opcional'),
            isActive: _step >= 3,
            state: StepState.indexed,
            content: _buildStep3(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Punto de origen'),
        const SizedBox(height: 8),
        _LocationButton(
          label: _origin?.name ?? 'Seleccionar origen en el mapa',
          icon: Icons.my_location,
          selected: _origin != null,
          onTap: () => _pickLocation(isOrigin: true),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Punto de destino'),
        const SizedBox(height: 8),
        _LocationButton(
          label: _destination?.name ?? 'Seleccionar destino en el mapa',
          icon: Icons.location_on_outlined,
          selected: _destination != null,
          onTap: () => _pickLocation(isOrigin: false),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Fecha y hora de salida'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: _departureDate == null
                      ? 'Seleccionar fecha'
                      : _fmtDate(_departureDate!),
                  onTap: _pickDate,
                  filled: _departureDate != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_outlined,
                  label: _departureTime == null
                      ? 'Hora'
                      : _departureTime!.format(context),
                  onTap: _pickTime,
                  filled: _departureTime != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Precio por cupo'),
          TextFormField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Precio (COP)',
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'ej: 5000',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El precio es requerido.';
              final n = double.tryParse(v.trim());
              if (n == null || n < 0) return 'Ingresa un precio valido (>= 0).';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return vehiclesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No se pudo cargar tus vehículos.'),
      ),
      data: (vehicles) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aún no tienes vehículos. Puedes agregar uno ahora.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _VehicleRadioTile(
              title: 'Sin vehículo',
              subtitle: 'No asociar vehículo a esta ruta',
              icon: Icons.remove_circle_outline,
              selected: _selectedVehicle == null,
              onTap: () => setState(() => _selectedVehicle = null),
            ),
            const SizedBox(height: 8),
            ...vehicles.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VehicleRadioTile(
                title: '${v.brand} ${v.model}',
                subtitle: '${v.plate} · ${v.color}',
                icon: Icons.directions_car_outlined,
                selected: _selectedVehicle?.id == v.id,
                onTap: () => setState(() => _selectedVehicle = v),
              ),
            )),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showAddVehicleSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar nuevo vehículo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Tipo de disponibilidad'),
        const SizedBox(height: 12),

        // Option: none
        _AvailOptionTile(
          title: 'No agregar ahora',
          subtitle: 'Puedes configurarlo luego desde "Mis rutas"',
          icon: Icons.schedule_outlined,
          selected: _availKind == _AvailKind.none,
          onTap: () => setState(() => _availKind = _AvailKind.none),
        ),
        const SizedBox(height: 8),

        // Option: specific date
        _AvailOptionTile(
          title: 'Fecha específica',
          subtitle: 'Un día puntual con cupos disponibles',
          icon: Icons.event_outlined,
          selected: _availKind == _AvailKind.specificDate,
          onTap: () => setState(() {
            _availKind = _AvailKind.specificDate;
            _specificDate ??= _departureDate;
          }),
        ),
        if (_availKind == _AvailKind.specificDate) ...[
          const SizedBox(height: 12),
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            label: _specificDate == null
                ? 'Seleccionar fecha'
                : _fmtDate(_specificDate!),
            onTap: _pickSpecificDate,
            filled: _specificDate != null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _specificSeatsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cupos disponibles',
              prefixIcon: Icon(Icons.event_seat_outlined),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Option: weekly
        _AvailOptionTile(
          title: 'Recurrencia semanal',
          subtitle: 'Días de la semana que ofreces cupo regularmente',
          icon: Icons.repeat_outlined,
          selected: _availKind == _AvailKind.weekly,
          onTap: () => setState(() => _availKind = _AvailKind.weekly),
        ),
        if (_availKind == _AvailKind.weekly) ...[
          const SizedBox(height: 12),
          const _SectionLabel('Días de la semana'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              return FilterChip(
                label: Text(_dayLabels[i]),
                selected: _weekdays[i],
                onSelected: (v) => setState(() => _weekdays[i] = v),
                selectedColor: AppColors.primary.withAlpha(40),
                checkmarkColor: AppColors.primaryDark,
                side: BorderSide(
                    color: _weekdays[i]
                        ? AppColors.primary
                        : AppColors.border),
              );
            }),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Rango de fechas'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Desde: ${_fmtDate(_rangeStart)}',
                  onTap: _pickRangeStart,
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hasta: ${_fmtDate(_rangeEnd)}',
                  onTap: _pickRangeEnd,
                  filled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weeklySeatsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cupos por día',
              prefixIcon: Icon(Icons.event_seat_outlined),
            ),
          ),
        ],
      ],
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

// ── Shared section label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

// ── Availability option tile ───────────────────────────────────────────────────

class _AvailOptionTile extends StatelessWidget {
  const _AvailOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(15) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vehicle radio tile ────────────────────────────────────────────────────────

class _VehicleRadioTile extends StatelessWidget {
  const _VehicleRadioTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(15) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location button ────────────────────────────────────────────────────────────

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withAlpha(15) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textHint,
                  fontWeight:
                      selected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.map_outlined,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Picker tile ────────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary.withAlpha(15) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: filled ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: filled ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: filled
                      ? AppColors.primaryDark
                      : AppColors.textHint,
                  fontWeight:
                      filled ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
