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

  String _dropdownValue='amount';
  
  void dropDownCallBack(String? selectedValue) {
    if(selectedValue is String) {
      setState(() {
        _dropdownValue = selectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Theme.of(context).primaryColor;

    final box = Hive.box<Transaction>('transactions');
    final transactions = box.values.toList();
    transactions.sort((a,b) => b.date.compareTo(a.date));

    Map<String, List<Transaction>> grouped = {};

    for(var tx in transactions)
    {
      final formatter=DateFormat('d MMM yyyy');
      final dateKey=formatter.format(tx.date);
      if(grouped[dateKey]==null)
      {
        grouped[dateKey]=[];
      }
      grouped[dateKey]!.add(tx);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Sort by', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Container( //de modificat-nu o sa ramana asa
                    padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColor, width: 1)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(items: const 
                        [
                          DropdownMenuItem(child: Text("amount"), value: "amount"),
                          DropdownMenuItem(child: Text("date"), value: "date"),
                        ], 
                        value: _dropdownValue,
                        onChanged: dropDownCallBack,
                        iconEnabledColor: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
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
                            ...txList.map((tx) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                                child: ListTile(
                                  leading: const Icon(Icons.monetization_on, color: Colors.green),
                                  title: Text(tx.category),
                                  trailing: Text("${tx.amount.toStringAsFixed(2)} USD",
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }
                    ).toList(),
                  
                ),
              ),
            ],
          ),
    );
  }
}