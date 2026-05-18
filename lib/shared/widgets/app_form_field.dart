import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

/// Champ de formulaire standardisé — icône, style filled, validation inline.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, color: AppColors.text1),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.text2)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
      ),
    );
  }
}

/// Dropdown standardisé avec le même style que AppFormField.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.text1),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.text2),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.text2)
            : null,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
      ),
    );
  }
}

/// Sélecteur de date avec le style AppFormField.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefixIcon = Icons.calendar_today_outlined,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final IconData prefixIcon;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;

  String get _formatted => value != null
      ? '${value!.day.toString().padLeft(2, '0')}/'
        '${value!.month.toString().padLeft(2, '0')}/'
        '${value!.year}'
      : '';

  @override
  Widget build(BuildContext context) {
    return AppFormField(
      label: label,
      initialValue: _formatted,
      prefixIcon: prefixIcon,
      readOnly: true,
      validator: validator,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1950),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.text2),
    );
  }
}

/// Section titre dans un formulaire multi-étapes.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 12, color: AppColors.text2)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

/// Badge indicateur d'étape (stepper custom léger).
class AppStepIndicator extends StatelessWidget {
  const AppStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone || isActive
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.primary
                                : isActive
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                            border: isActive
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.white : Colors.grey.shade500,
                                    ),
                                  ),
                          ),
                        ),
                        if (i < totalSteps - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (i < labels.length)
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive || isDone ? AppColors.primary : Colors.grey.shade400,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
