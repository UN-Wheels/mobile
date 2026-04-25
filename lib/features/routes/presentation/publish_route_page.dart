import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/routes_api.dart';

class PublishRoutePage extends ConsumerStatefulWidget {
  const PublishRoutePage({super.key});

  @override
  ConsumerState<PublishRoutePage> createState() => _PublishRoutePageState();
}

class _PublishRoutePageState extends ConsumerState<PublishRoutePage> {
  int _step = 0;
  bool _submitting = false;

  // Step 0 — Ruta
  final _originNameCtrl = TextEditingController();
  final _originLatCtrl = TextEditingController();
  final _originLngCtrl = TextEditingController();
  final _destNameCtrl = TextEditingController();
  final _destLatCtrl = TextEditingController();
  final _destLngCtrl = TextEditingController();
  final _step0Key = GlobalKey<FormState>();

  // Step 1 — Horario y precio
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  final _priceCtrl = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  // Step 2 — Disponibilidad (semanal, opcional)
  bool _addAvailability = false;
  final List<bool> _weekdays = List.filled(7, false); // index 0=Lun … 6=Dom
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 90));
  final _seatsCtrl = TextEditingController(text: '2');

  static const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void dispose() {
    _originNameCtrl.dispose();
    _originLatCtrl.dispose();
    _originLngCtrl.dispose();
    _destNameCtrl.dispose();
    _destLatCtrl.dispose();
    _destLngCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _continue() {
    if (_step == 0 && !(_step0Key.currentState?.validate() ?? false)) return;
    if (_step == 1 && !_validateStep1()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
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

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dt = _departureDate!;
      final t = _departureTime!;
      final departureDt = DateTime(dt.year, dt.month, dt.day, t.hour, t.minute);

      final routeData = {
        'origin': {
          'name': _originNameCtrl.text.trim(),
          'lat': double.tryParse(_originLatCtrl.text.trim()) ?? 0.0,
          'lng': double.tryParse(_originLngCtrl.text.trim()) ?? 0.0,
        },
        'destination': {
          'name': _destNameCtrl.text.trim(),
          'lat': double.tryParse(_destLatCtrl.text.trim()) ?? 0.0,
          'lng': double.tryParse(_destLngCtrl.text.trim()) ?? 0.0,
        },
        'departureTime': departureDt.toUtc().toIso8601String(),
        'pricePerSeat': double.parse(_priceCtrl.text.trim()),
        'status': 'ACTIVE',
      };

      final created = await ref.read(routesApiProvider).createRoute(routeData);

      if (_addAvailability && _weekdays.any((d) => d)) {
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
            'seatsPerOccurrence': int.parse(_seatsCtrl.text.trim()),
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

  // ── Date / time pickers ─────────────────────────────────────────────────────

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

  // ── Build ───────────────────────────────────────────────────────────────────

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
            children: [
              ElevatedButton(
                onPressed: _submitting ? null : details.onStepContinue,
                child: _submitting && _step == 2
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(_step == 2 ? 'Publicar' : 'Continuar'),
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
            title: const Text('Disponibilidad'),
            subtitle: const Text('Opcional'),
            isActive: _step >= 2,
            state: StepState.indexed,
            content: _buildStep2(),
          ),
        ],
      ),
    );
  }

  // ── Step 0 ─────────────────────────────────────────────────────────��───────

  Widget _buildStep0() {
    return Form(
      key: _step0Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Punto de origen'),
          _field(_originNameCtrl, 'Nombre del lugar', Icons.my_location, required: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_originLatCtrl, 'Latitud', Icons.south, hint: 'ej: 4.6486', isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_originLngCtrl, 'Longitud', Icons.east, hint: 'ej: -74.0637', isNum: true)),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Punto de destino'),
          _field(_destNameCtrl, 'Nombre del lugar', Icons.location_on, required: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_destLatCtrl, 'Latitud', Icons.south, hint: 'ej: 4.6486', isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_destLngCtrl, 'Longitud', Icons.east, hint: 'ej: -74.0637', isNum: true)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'En una próxima versión podrás seleccionar los puntos directamente en el mapa.',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

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
                  label: _departureDate == null ? 'Seleccionar fecha' : _fmtDate(_departureDate!),
                  onTap: _pickDate,
                  filled: _departureDate != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_outlined,
                  label: _departureTime == null ? 'Hora' : _departureTime!.format(context),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Precio (COP)',
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'ej: 5000',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El precio es requerido.';
              final n = double.tryParse(v.trim());
              if (n == null || n < 0) return 'Ingresa un precio válido (≥ 0).';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Agregar disponibilidad semanal'),
          subtitle: const Text('Días que ofreces cupo regularmente'),
          value: _addAvailability,
          onChanged: (v) => setState(() => _addAvailability = v),
          activeThumbColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        if (_addAvailability) ...[
          const SizedBox(height: 8),
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
                side: BorderSide(color: _weekdays[i] ? AppColors.primary : AppColors.border),
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
            controller: _seatsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cupos por día',
              prefixIcon: Icon(Icons.event_seat_outlined),
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) return 'Mínimo 1 cupo.';
              return null;
            },
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                    'Puedes agregar fechas disponibles después desde "Mis rutas".',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    bool required = false,
    bool isNum = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(signed: true, decimal: true) : TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido.' : null
          : null,
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

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
          border: Border.all(color: filled ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: filled ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: filled ? AppColors.primaryDark : AppColors.textHint,
                  fontWeight: filled ? FontWeight.w500 : FontWeight.normal,
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
