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
  final _converter = TextEditingController();
  final _converterKey = GlobalKey<FormState>();

  Stream<BitcoinModel>? btcStream;

  String _currencyType = 'USD';
  String _btcConvert = '21151661.30';

  /// List of currency type selector
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

  @override
  void initState() {
    btcService.initial();
    btcStream = btcService.getStream;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('BTC Rate Sample',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Row(
            children: [
              InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => const BtcLogDialog(),
                ),
                child: Ink(
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 15)
            ],
          ),
        ],
      ),
      body: StreamBuilder<BitcoinModel>(
          stream: btcStream,
          builder: (context, AsyncSnapshot<BitcoinModel> snapshot) {
            final data = snapshot.data;
            if (snapshot.hasError) {
              return const Text("Error to fetch the api");
            }
            if (snapshot.hasData) {
              return Column(children: [
                /// List of currency rate that 1 BTC per value
                /// USD, GBP, EUR
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                      padding: const EdgeInsets.all(15),
                      child: ListView.builder(
                          itemCount: data!.values.length,
                          itemExtent: constraints.maxHeight / 3 - 10,
                          itemBuilder: (context, index) {
                            return currencyCard(
                                data.values[index], constraints);
                          }),
                    );
                  }),
                ),

                /// Bitcoin value converter
                LayoutBuilder(builder: (context, constraints) {
                  return Container(
                    height: 150,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 31),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /// Select the converter type
                                DropdownButton<String>(
                                    underline: const SizedBox(),
                                    value: _currencyType,
                                    items: drops,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _currencyType = newValue!;
                                      });
                                    }),

                                /// Input the converter value
                                Expanded(
                                  child: Form(
                                    key: _converterKey,
                                    child: TextFormField(
                                      controller: _converter,
                                      decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 15),
                                          border: OutlineInputBorder(),
                                          hintText: 'BTC Converter'),
                                      onChanged: (value) {
                                        setState(() {
                                          _converterKey.currentState
                                              ?.validate();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return null;
                                        }
                                        if (validateCurrency(value)) {
                                          _btcConvert = convertToBTC(
                                            _currencyType,
                                            double.parse(value),
                                            data!.values
                                                .map((value) =>
                                                    value['rate'] as double)
                                                .toList(),
                                          );

                                          return null;
                                        } else {
                                          return 'Please enter a float number.';
                                        }
                                      },
                                    ),
                                  ),
                                )
                              ]),

                          /// Display result of converter
                          _converterKey.currentState?.validate() == true
                              ? Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    '$_btcConvert BTC',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      color: Colors.orange,
                                    ),
                                  ))
                              : const SizedBox()
                        ]),
                  );
                })
              ]);
            }

            /// Display loading when BTC stream not ready
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }),
    );
  }

  bool validateCurrency(String? input) {
    if (input == null || input.isEmpty) return false;

    String cleanedInput = input.trim();
    bool isCurrency = true;

    // Split the number
    List<String> unit = cleanedInput.split('.');

    // Check the number
    String numbers = unit[0];
    if (!validateNumber(numbers)) {
      isCurrency = false;
    }

    // Check the decimal
    if (unit.length == 2) {
      String decimal = unit[1];
      if (!validateNumber(decimal) || decimal.length > 2) {
        isCurrency = false;
      }
    }

    // Check the float number has only 2 units
    if (unit.length > 2) {
      isCurrency = false;
    }

    return isCurrency;
  }

  bool validateNumber(String num) {
    for (int i = 0; i < num.length; i++) {
      if (num[i] != ',' && int.tryParse(num[i]) is! int) {
        return false;
      }
    }
    return true;
  }

  // Convert any currency value to the BTC value
  String convertToBTC(String type, double value, List<double> rates) {
    final formatCurrency = NumberFormat.currency(
      customPattern: '###,##0.00',
    );
    switch (type) {
      case 'USD':
        return formatCurrency.format(value / rates[0]);
      case 'GBP':
        return formatCurrency.format(value / rates[1]);
      case 'EUR':
        return formatCurrency.format(value / rates[2]);
      default:
        return formatCurrency.format(value / rates[0]);
    }
  }

  // Currency display
  Widget currencyCard(Map value, BoxConstraints constraints) {
    String currencyName = (value['name'] as String).toUpperCase();
    final formatCurrency = NumberFormat.currency(
      customPattern: '###,##0.00',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black87,
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(15),
      child: constraints.maxHeight < 600
          ? Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyName,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                Align(
                  child: Text(
                    formatCurrency.format(value['rate']),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    currencyName,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    formatCurrency.format(value['rate']),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
