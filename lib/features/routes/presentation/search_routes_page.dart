import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/routes_providers.dart';
import '../data/search_api.dart';
import '../domain/app_route.dart';

class SearchRoutesPage extends ConsumerStatefulWidget {
  const SearchRoutesPage({super.key});

  @override
  ConsumerState<SearchRoutesPage> createState() => _SearchRoutesPageState();
}

class _SearchRoutesPageState extends ConsumerState<SearchRoutesPage> {
  final _originCtrl   = TextEditingController();
  final _destCtrl     = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;

  bool get _hasFilters =>
      _originCtrl.text.trim().isNotEmpty ||
      _destCtrl.text.trim().isNotEmpty ||
      _selectedDate != null ||
      _timeFrom != null ||
      _timeTo != null ||
      _maxPriceCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final params = SearchRoutesParams(
      originName: _originCtrl.text.trim().isEmpty ? null : _originCtrl.text.trim(),
      destName:   _destCtrl.text.trim().isEmpty   ? null : _destCtrl.text.trim(),
      date:       _selectedDate,
      timeFrom:   _timeFrom == null ? null
          : '${_timeFrom!.hour.toString().padLeft(2, '0')}:${_timeFrom!.minute.toString().padLeft(2, '0')}',
      timeTo:     _timeTo == null ? null
          : '${_timeTo!.hour.toString().padLeft(2, '0')}:${_timeTo!.minute.toString().padLeft(2, '0')}',
      maxPrice: double.tryParse(_maxPriceCtrl.text.trim()),
    );
    ref.read(searchParamsProvider.notifier).state = params;
  }

  void _clear() {
    _originCtrl.clear();
    _destCtrl.clear();
    _maxPriceCtrl.clear();
    setState(() {
      _selectedDate = null;
      _timeFrom     = null;
      _timeTo       = null;
    });
    ref.read(searchParamsProvider.notifier).state = null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isFrom ? _timeFrom : _timeTo) ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _timeFrom = picked;
        else        _timeTo   = picked;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchRoutesProvider);
    final params      = ref.watch(searchParamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar rutas'),
        actions: [
          if (_hasFilters)
            TextButton(
              onPressed: _clear,
              child: const Text(
                'Limpiar',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────────────────────
          _FilterPanel(
            originCtrl:   _originCtrl,
            destCtrl:     _destCtrl,
            maxPriceCtrl: _maxPriceCtrl,
            selectedDate: _selectedDate,
            timeFrom:     _timeFrom,
            timeTo:       _timeTo,
            onPickDate:   _pickDate,
            onPickTimeFrom: () => _pickTime(isFrom: true),
            onPickTimeTo:   () => _pickTime(isFrom: false),
            onSearch: _search,
          ),

          // ── Resultados ───────────────────────────────────────────────────
          Expanded(
            child: params == null
                // Estado inicial
                ? const _InitialHint()
                : searchAsync.when(
                    loading: () =>
                        const Loading(message: 'Buscando rutas...'),
                    error: (e, _) => EmptyState(
                      message: 'No se pudieron cargar las rutas.',
                      icon: Icons.wifi_off_outlined,
                      actionLabel: 'Reintentar',
                      onAction: _search,
                    ),
                    data: (result) {
                      if (result == null || result.routes.isEmpty) {
                        return EmptyState(
                          message: 'No se encontraron rutas.\n'
                              'Intenta con otros filtros.',
                          icon: Icons.search_off_outlined,
                          actionLabel: 'Limpiar filtros',
                          onAction: _clear,
                        );
                      }
                      return _ResultsList(result: result);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Panel de filtros ──────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.originCtrl,
    required this.destCtrl,
    required this.maxPriceCtrl,
    required this.selectedDate,
    required this.timeFrom,
    required this.timeTo,
    required this.onPickDate,
    required this.onPickTimeFrom,
    required this.onPickTimeTo,
    required this.onSearch,
  });

  final TextEditingController originCtrl;
  final TextEditingController destCtrl;
  final TextEditingController maxPriceCtrl;
  final DateTime?   selectedDate;
  final TimeOfDay?  timeFrom;
  final TimeOfDay?  timeTo;
  final VoidCallback onPickDate;
  final VoidCallback onPickTimeFrom;
  final VoidCallback onPickTimeTo;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final dateLabel = selectedDate != null
        ? DateFormat('dd MMM yyyy', 'es').format(selectedDate!)
        : 'Fecha';
    final fromLabel = timeFrom != null
        ? timeFrom!.format(context)
        : 'Desde';
    final toLabel = timeTo != null
        ? timeTo!.format(context)
        : 'Hasta';

    return Container(
      color: AppColors.authBg2,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          // Origen
          TextField(
            controller: originCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              hint: 'Origen (barrio o lugar)',
              icon: Icons.my_location,
              iconColor: AppColors.primary,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),

          // Destino
          TextField(
            controller: destCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              hint: 'Destino (barrio o lugar)',
              icon: Icons.location_on_outlined,
              iconColor: AppColors.secondary,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),

          // Fecha + hora desde + hora hasta
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _ChipButton(
                  label: dateLabel,
                  icon: Icons.calendar_today_outlined,
                  active: selectedDate != null,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _ChipButton(
                  label: fromLabel,
                  icon: Icons.schedule_outlined,
                  active: timeFrom != null,
                  onTap: onPickTimeFrom,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _ChipButton(
                  label: toLabel,
                  icon: Icons.schedule_outlined,
                  active: timeTo != null,
                  onTap: onPickTimeTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Precio máximo + botón buscar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: maxPriceCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: 'Precio máx. (COP)',
                    icon: Icons.attach_money,
                    iconColor: AppColors.success,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Buscar',
                onPressed: onSearch,
                icon: Icons.search,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: iconColor),
        filled: true,
        fillColor: Colors.white10,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );
}

// ── Chip selector (fecha / hora) ──────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withAlpha(40)
              : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 13,
                color: active ? AppColors.primary : Colors.white38),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.primary : Colors.white54,
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
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

// ── Hint inicial ──────────────────────────────────────────────────────────────

class _InitialHint extends StatelessWidget {
  const _InitialHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined,
                size: 56, color: AppColors.textHint.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              'Busca rutas por nombre de barrio,\nfecha, hora o precio máximo.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de resultados ───────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.result});

  final SearchRoutesResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${result.total} ruta${result.total != 1 ? 's' : ''} encontrada${result.total != 1 ? 's' : ''}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),

        // Tarjetas
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: result.routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _RouteCard(route: result.routes[i]),
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de ruta (idéntica a la original) ──────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    final driver = route.driver;
    final driverLabel =
        driver != null ? driver.displayName : route.driverId;
    final driverInitials =
        driver != null ? driver.initials : _initials(route.driverId);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(RouteNames.routeDetailOf(route.id)),
      child: Column(
        children: [
          // Accent bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origen
                Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.origin.name,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Container(
                      width: 2, height: 12, color: AppColors.border),
                ),
                // Destino
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.destination.name,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Meta row
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatTime(route.departureTime),
                        style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.attach_money,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '\$${route.pricePerSeat.toStringAsFixed(0)}/cupo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    AppBadge(
                      label: route.isActive ? 'Activa' : route.status,
                      type: route.isActive
                          ? BadgeType.success
                          : BadgeType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Driver row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withAlpha(30),
                      child: Text(
                        driverInitials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driverLabel,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _initials(String text) =>
      text.isEmpty ? '?' : text[0].toUpperCase();
}
