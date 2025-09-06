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

  Map<String, IconData> categoryIcons = {
      "food": Icons.fastfood,
      "travel": Icons.directions_car,
      "shopping": Icons.shopping_bag,
      "entertainment": Icons.movie,
      "utilities": Icons.lightbulb,
      "other": Icons.category,
  };

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
    Color themeColor = Theme.of(context).primaryColor;
    
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
                                leading: Icon(categoryIcons[tx.category.toLowerCase()] ?? Icons.help_outline, color: themeColor),
                                title: Text(tx.category),
                                subtitle: Text("${tx.amount.toStringAsFixed(2)} USD",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: PopupMenuButton(itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: popupItem,
                                      child: Text(popupItem))
                                ],
                                onSelected: (String popupItem) {
                                  if(popupItem == 'Delete')
                                  {
                                    deleteDialog(box, mapEntry);
                                  }
                                }),
                              ),
                            );
                          }),
                        ],
                      );
                    }
                  ).toList(),
              ),
            );
  }

                Future<dynamic> deleteDialog(Box<Transaction> box, MapEntry<dynamic, Transaction?> mapEntry) {
                  return showDialog(
                                    context: context, 
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text("Are you sure you want to delete the transaction?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            }),
                                            TextButton(
                                              child: const Text("Confirm"),
                                              onPressed: () {
                                                setState(() {
                                                    box.delete(mapEntry.key);
                                                  });
                                                Navigator.of(context).pop();
                                              },)
                                        ],
                                      );
                                    }
                                  );
                    }
                  }
