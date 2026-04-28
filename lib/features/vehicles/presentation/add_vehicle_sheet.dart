import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/application/profile_providers.dart';

class AddVehicleSheet extends ConsumerStatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  ConsumerState<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _type = 'car';
  bool _saving = false;

  static const _types = [
    ('car', 'Automóvil'),
    ('motorcycle', 'Motocicleta'),
    ('van', 'Camioneta'),
    ('bicycle', 'Bicicleta'),
    ('other', 'Otro'),
  ];

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final yearVal = int.tryParse(_yearCtrl.text.trim());
      await ref.read(vehiclesProvider.notifier).addVehicle({
        'plate': _plateCtrl.text.trim().toUpperCase(),
        'vehicle_type': _type,
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        if (yearVal != null) 'year': yearVal,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo agregado.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Agregar vehículo', style: AppTextStyles.h4),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de vehículo',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text(t.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'car'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  prefixIcon: Icon(Icons.pin_outlined),
                  hintText: 'ej: ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido.' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandCtrl,
                      decoration: const InputDecoration(labelText: 'Marca'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yearCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        hintText: 'ej: 2020',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido.';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                          return 'Año inválido.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Agregar vehículo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAddVehicleSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const AddVehicleSheet(),
  );
}
