import 'package:intl/intl.dart';

String money(double value, {String currency = 'INR'}) {
  final locale = currency == 'INR' ? 'en_IN' : 'en_US';
  return NumberFormat.simpleCurrency(
    name: currency,
    locale: locale,
  ).format(value);
}

String shortDate(DateTime date) => DateFormat('d MMM yyyy').format(date);
String monthName(DateTime date) => DateFormat('MMMM yyyy').format(date);
