import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:moneyapp/transaction_model.dart';

class StatsPage extends StatefulWidget {
  StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _dropdownValue='daily';

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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: 
        Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Show', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Container( //de modificat-nu o sa ramana asa
                    padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 2),
                    // decoration: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(20),
                    //   border: Border.all(color: themeColor, width: 1)
                    // ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(items:  
                        [
                          DropdownMenuItem(value: "daily", child: Text("daily")),
                          DropdownMenuItem(value: "weekly", child: Text("weekly")),
                          DropdownMenuItem(value: "monthly", child: Text("monthly")),
                          DropdownMenuItem(value: "yearly", child: Text("yearly")),
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
                child: box.isEmpty ? 
                    Center(
                      child: const Column(
                        children: [
                          Icon(Icons.insert_chart_outlined, size: 60),
                          const SizedBox(height: 12),
                          Text("No transactions registered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          ]
                      ),
                    )
                    : Column(
                      children: [
                        Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.account_balance_wallet),
                                  title: Text("Total spent: "),
                                ),
                              ),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.trending_up),
                                  title: Text("Transactions: "),
                                  )
                                ),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.leaderboard),
                                  title: Text("Top category: "),
                                  )
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                ),
          ],
        ),
    );
  }
}