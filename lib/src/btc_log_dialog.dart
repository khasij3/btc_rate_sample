import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'local_storage_service.dart';
import 'btc_model.dart';

class BtcLogDialog extends StatefulWidget {
  const BtcLogDialog({super.key});

  @override
  State<BtcLogDialog> createState() => _BtcLogDialogState();
}

class _BtcLogDialogState extends State<BtcLogDialog> {
  final localStorage = LocalStorageService();
  List<BitcoinModel>? logs;

  @override
  void initState() {
    initDialog();
    super.initState();
  }

  void initDialog() async {
    logs = await localStorage.getAllBtcLog()
      ..sort((a, b) => b.updated.compareTo(a.updated));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('BTC Rate Log'),
      actionsAlignment: MainAxisAlignment.end,
      content: logs != null
          ? SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: logs!.length,
                itemBuilder: (context, index) {
                  final formatter = DateFormat('MMM dd, yyyy HH:mm');
                  final updated = formatter.format(logs![index].updated);

                  String valuesText = logs![index].values.map((value) {
                    return '${value['name']} : ${value['rate']}';
                  }).join('\n');

                  return ListTile(
                    title: Text('[$updated]'),
                    subtitle: Text(valuesText),
                  );
                },
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      actions: [
        /// clear log button
        TextButton(
            child: const InkWell(
              child: Text('clear',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  )),
            ),
            onPressed: () async {
              await localStorage.removeAllBtcLog();
              setState(() => logs = []);
            }),

        /// close dialog button
        TextButton(
          child: const InkWell(
            child: Text('close',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                )),
          ),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }
}
