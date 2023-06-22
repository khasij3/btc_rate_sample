import 'package:btc_rate_sample/src/btc_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // Obtain shared preferences.
  Future<void> addBtcLog(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(key, value);
  }

  Future<List<String>?> getBtcLog(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<List<BitcoinModel>> getAllBtcLog() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    List<BitcoinModel> models = [];

    for (String key in keys) {
      final keyValues = await getBtcLog(key);
      List<Map<String, dynamic>> values = [];
      DateTime updated = DateTime.fromMillisecondsSinceEpoch(int.parse(key));

      for (var i = 0; i < keyValues!.length; i++) {
        final stringSplit = keyValues[i].split(':');
        values.add({
          'name': stringSplit[0],
          'rate': stringSplit[1],
        });
      }

      models.add(BitcoinModel(
        values: values,
        updated: updated,
      ));
    }

    return models;
  }

  Future<void> removeAllBtcLog() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      prefs.remove(key);
    }
  }
}
