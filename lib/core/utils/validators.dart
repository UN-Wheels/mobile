abstract final class Validators {
  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'Este campo'} es requerido.';
    }
    return null;
  }

  static String? unalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido.';
    }
    if (!value.trim().endsWith('@unal.edu.co')) {
      return 'Debe ser un correo @unal.edu.co';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida.';
    if (value.length < 8) return 'Mínimo 8 caracteres.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido.';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Teléfono inválido.';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'La edad es requerida.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Ingresa un número válido.';
    if (parsed < 15 || parsed > 90) return 'Edad debe estar entre 15 y 90.';
    return null;
  }

  static String? positiveNumber(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'Este campo'} es requerido.';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Debe ser un número positivo.';
    }
    return null;
  }
}
