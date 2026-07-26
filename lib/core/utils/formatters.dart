import 'package:intl/intl.dart';
import '../constants.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: AppConstants.localeIndia,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String dateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  static String date(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String time(DateTime dt) {
    return _timeFormat.format(dt);
  }
}
