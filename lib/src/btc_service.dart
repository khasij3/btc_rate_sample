import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../src/btc_model.dart';
import '../src/local_storage_service.dart';

class BitcoinService with ChangeNotifier {
  final _controller = StreamController<BitcoinModel>();
  final _localStorage = LocalStorageService();
  final _oldValues = [];

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  /// The bitcoin rate stream
  Stream<BitcoinModel> get getStream => _controller.stream;

  /// Initial the bitcoin rate streaming
  /// Should call this function first to be work
  Future<void> initial() async {
    /// Set refresh time closer to the current time-date data
    /// By set second different between app run time and time-date data
    /// if the updated time is not specified in seconds will be default
    DateTime serverDelay = await _updateData();
    int secondDiff = 60 - serverDelay.second;

    await Future.delayed(
      Duration(seconds: secondDiff),
      () => _updateData(),
    );

    /// Update stream every 1 minute
    Timer.periodic(const Duration(minutes: 1), (_) {
      _updateData();
    });
  }

  /// Update the bitcoin rate data from api
  Future<DateTime> _updateData() async {
    DateTime updated = DateTime.now();
    final res = await http.get(
      Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json'),
    );

    if (res.statusCode == 200) {
      final data = BitcoinModel.fromJson(jsonDecode(res.body));
      List<String> values = [];
      for (var i = 0; i < data.values.length; i++) {
        String name = data.values[i]['name'];
        String rate = data.values[i]['rate'].toString();

        values.add('$name:$rate');
      }

      /// Update stream
      _controller.add(data);

      /// Upload data to local storage
      int updatedInEpoch = updated.millisecondsSinceEpoch;
      _localStorage.addBtcLog(updatedInEpoch.toString(), values);

      return data.updated;
    } else {
      throw Exception('Fetch data is failed.');
    }
  }
}
