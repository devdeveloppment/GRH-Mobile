class FormValidators {
  const FormValidators._();

  /// Valide un email
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email requis';
    }
    const emailRegex =
        r'^[a-zA-Z0-9.!#$%&"*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$';
    if (!RegExp(emailRegex).hasMatch(value!)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Mot de passe requis';
    }
    if ((value?.length ?? 0) < 6) {
      return 'Minimum 6 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return 'Au moins une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Au moins une minuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Au moins un chiffre';
    }
    return null;
  }

  /// Valide un champ obligatoire
  static String? validateRequired(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Ce champ est requis';
    }
    return null;
  }

  /// Valide un numéro de téléphone Togolais
  static String? validatePhoneTG(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Téléphone requis';
    }
    // Format: 228XXXXXXXX (with country code) or XXXXXXXX (without)
    final cleanedValue = value!.replaceAll(RegExp(r'[\s\-\.\+]'), '');
    // Remove leading 00 if present (00228 -> 228)
    final normalizedValue = cleanedValue.replaceFirst(RegExp(r'^00'), '');
    const phoneRegex = r'^228[2-9]\d{7}$|^[2-9]\d{7}$';
    if (!RegExp(phoneRegex).hasMatch(normalizedValue)) {
      return 'Numéro Togo invalide';
    }
    return null;
  }

  /// Valide une plage de dates
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Dates requises';
    }
    if (endDate.isBefore(startDate)) {
      return 'La date fin doit être après la date début';
    }
    return null;
  }

  /// Valide un montant
  static String? validateAmount(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Montant requis';
    }
    final amount = double.tryParse(value!);
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    return null;
  }

  /// Valide un nombre de jours de congé
  static String? validateLeaveDays(String? value, int maxDays) {
    if (value?.isEmpty ?? true) {
      return 'Nombre de jours requis';
    }
    final days = int.tryParse(value!);
    if (days == null || days <= 0) {
      return 'Nombre invalide';
    }
    if (days > maxDays) {
      return 'Dépasse le solde disponible ($maxDays jours)';
    }
    return null;
  }
}
