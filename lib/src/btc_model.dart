import 'package:intl/intl.dart';

class BitcoinModel {
  final List<Map<String, dynamic>> values;
  final DateTime updated;

  const BitcoinModel({
    required this.values,
    required this.updated,
  });

  factory BitcoinModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> values = [
      {'name': 'usd', 'rate': json['bpi']['USD']['rate_float'] as double},
      {'name': 'gbp', 'rate': json['bpi']['GBP']['rate_float'] as double},
      {'name': 'eur', 'rate': json['bpi']['EUR']['rate_float'] as double},
    ];

    final formatter = DateFormat('MMM dd, yyyy HH:mm:ss zzz');
    DateTime updated = formatter.parse(json['time']['updated']);

    return BitcoinModel(values: values, updated: updated);
  }
}
