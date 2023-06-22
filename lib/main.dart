import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'src/btc_model.dart';
import 'src/btc_service.dart';
import 'src/btc_log_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BTC Rate',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final btcService = BitcoinService();
  final converter = TextEditingController();

  String currencyType = 'USD';
  String btcConvert = '';

  List<DropdownMenuItem<String>> drops = const [
    DropdownMenuItem(
      value: 'USD',
      child: Text('USD'),
    ),
    DropdownMenuItem(
      value: 'GBP',
      child: Text('GBP'),
    ),
    DropdownMenuItem(
      value: 'EUR',
      child: Text('EUR'),
    ),
  ];

  Stream<BitcoinModel>? btcStream;

  @override
  void initState() {
    btcService.initial();
    btcStream = btcService.getStream;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: const Text(
          'BTC Rate Sample',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<BitcoinModel>(
          stream: btcStream,
          builder: (context, AsyncSnapshot<BitcoinModel> snapshot) {
            final data = snapshot.data;
            if (snapshot.hasError) {
              return const Text("Error to fetch the api");
            }
            if (snapshot.hasData) {
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                        builder: (context, BoxConstraints constraints) {
                      return Container(
                        padding: const EdgeInsets.all(15),
                        child: ListView.builder(
                          itemCount: data!.values.length,
                          itemExtent: constraints.maxHeight / 3 - 10,
                          itemBuilder: (context, index) {
                            return currencyCard(data.values[index]);
                          },
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(15),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DropdownButton<String>(
                                  underline: const SizedBox(),
                                  value: currencyType,
                                  items: drops,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      currencyType = newValue!;
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 240,
                                  child: TextFormField(
                                    controller: converter,
                                    onChanged: (value) {
                                      convertToBTC(
                                          currencyType,
                                          value as double,
                                          data!.values
                                              .map((value) =>
                                                  value['rate'] as double)
                                              .toList());
                                    },
                                    decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        border: OutlineInputBorder(),
                                        hintText: 'BTC Converter'),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Center(
                            child: Text(btcConvert,
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Colors.orange,
                                )),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            ));
          }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black87,
        shape: const CircleBorder(),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const BtcLogDialog(),
          );
        },
        child: const Icon(Icons.history, color: Colors.white),
      ),
    );
  }

  double convertToBTC(String type, double value, List<double> rates) {
    switch (type) {
      case 'USD':
        return value / rates[0];
      case 'GBP':
        return value / rates[1];
      case 'EUR':
        return value / rates[2];
      default:
        return 0.0;
    }
  }

  Widget currencyCard(Map value) {
    String currencyName = (value['name'] as String).toUpperCase();
    final formatCurrency = NumberFormat.currency(
      customPattern: '###,##0.00 $currencyName',
    );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.black87,
      elevation: 5.0,
      child: Center(
        child: Text(
          formatCurrency.format(value['rate']),
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
