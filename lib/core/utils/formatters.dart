import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_TG',
    symbol: 'FCFA',
    decimalDigits: 0,
    customPattern: '#,##0 ¤',
  );

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy', 'fr_TG');
  static final DateFormat _longDate = DateFormat('EEEE d MMMM y', 'fr_TG');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'fr_TG');
  static final DateFormat _time = DateFormat('HH:mm', 'fr_TG');

  static String currency(num? value) => _currencyFormat.format(value ?? 0);

  static String shortDate(DateTime? value) {
    if (value == null) {
      return 'N/A';
    }
    return _shortDate.format(value);
  }

  static String longDate(DateTime? value) {
    if (value == null) {
      return 'N/A';
    }
    final text = _longDate.format(value);
    return text[0].toUpperCase() + text.substring(1);
  }

  static String monthYear(DateTime value) => _monthYear.format(value);

  static String time(DateTime? value) {
    if (value == null) {
      return '--:--';
    }
    return _time.format(value);
  }

  static String relativeTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inSeconds < 60) {
      return 'À l’instant';
    }
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }
    if (difference.inDays == 1) {
      return 'Hier';
    }
    return shortDate(value);
  }
}
