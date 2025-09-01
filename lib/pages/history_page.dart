import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; //for date formatting

import 'package:moneyapp/transaction_model.dart';

class HistoryPage extends StatefulWidget {
  HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String popupItem='Delete';

  @override
  Widget build(BuildContext context) {

    final box = Hive.box<Transaction>('transactions');
    final transactions = box.keys.map((key) {
      final tx=box.get(key);
      return MapEntry(key, tx);
    }).toList();
    transactions.sort((a, b) => b.value!.date.compareTo(a.value!.date));

    Map<String, List<MapEntry<dynamic, Transaction?>>> grouped = {};

    for(var entry in transactions)
    {
      final formatter=DateFormat('d MMM yyyy');
      final dateKey=formatter.format(entry.value!.date);
      
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
            children: [
              const SizedBox(height: 30),
              transactionsListTile(grouped, box),
            ],
          ),
    );
  }

  Expanded transactionsListTile(Map<String, List<MapEntry<dynamic, Transaction?>>> grouped, Box<Transaction> box) {
    return Expanded(
              child: ListView(
                children: 
                  grouped.entries.map((entry) {
                      final date=entry.key;
                      final txList=entry.value;
              
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          ...txList.map((mapEntry) {
                            final tx = mapEntry.value!;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                              child: ListTile(
                                leading: const Icon(Icons.monetization_on, color: Colors.green),
                                title: Text(tx.category),
                                subtitle: Text("${tx.amount.toStringAsFixed(2)} USD",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: PopupMenuButton(itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Text(popupItem),
                                      value: popupItem)
                                ],
                                onSelected: (String popupItem) {
                                  if(popupItem == 'Delete')
                                  {
                                    setState(() {
                                      box.delete(mapEntry.key);
                                    });
                                  }
                                }),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }
                  ).toList(),
              ),
            );
  }
}
