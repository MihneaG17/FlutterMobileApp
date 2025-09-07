import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart'; //for pie charts
import 'package:moneyapp/transaction_model.dart';

class StatsPage extends StatefulWidget {
  StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _dropdownValue='daily';
  TextEditingController _dateController = TextEditingController();

  void dropDownCallBack(String? selectedValue) {
    if(selectedValue is String) {
      setState(() {
        _dropdownValue = selectedValue;
      });
    }
  }

  @override
    void dispose() {
      _dateController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Theme.of(context).primaryColor;
    final box = Hive.box<Transaction>('transactions');
    final allTx = box.values.toList();

    DateTime selectedDate;
    if(_dateController.text.isEmpty) {
      selectedDate = DateTime.now();
      _dateController.text = selectedDate.toString().split(" ")[0];
    }
    else {
      selectedDate=DateTime.parse(_dateController.text);
    }

    final filteredTxDaily = allTx.where((tx) => 
      tx.date.year == selectedDate.year &&
      tx.date.month == selectedDate.month && 
      tx.date.day == selectedDate.day
    ).toList();
    
    final totalSpentDaily = filteredTxDaily.fold(0.0, (sum, tx) => sum + tx.amount);

    final transactionCountDaily = filteredTxDaily.length;

    Map<String, double> categoryTotalsDaily = {};
    Map<String, double> categoryExistingDaily = {};
    for(var tx in filteredTxDaily) {
      categoryTotalsDaily[tx.category] = (categoryTotalsDaily[tx.category] ?? 0) + tx.amount;
      categoryExistingDaily[tx.category] = (categoryExistingDaily[tx.category] ?? 0) + 1;
    }

    String topCategoryDaily = "None";

    if(categoryTotalsDaily.isNotEmpty) {
      topCategoryDaily = categoryTotalsDaily.entries.reduce((a,b) => a.value > b.value ? a : b).key;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: 
        ListView(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Show', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Container( //de modificat-nu o sa ramana asa
                    padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 2),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_chart_outlined, size: 60),
                          SizedBox(height: 12),
                          Text("No transactions registered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          ]
                      ),
                    )
                    : Column(
                      children: [
                        Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        SizedBox(height: 10),
                        Text("Select a date: ", style: TextStyle(fontSize: 14)),
                        SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            width: 170,
                            child: TextField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelStyle: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                                filled: true,
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none
                                ),
                              ),
                              readOnly: true,
                              onTap: () {
                                _selectDate();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.account_balance_wallet),
                                  title: Text("Total spent: "),
                                  trailing: Text("${totalSpentDaily.toStringAsFixed(2)} USD", style: TextStyle(fontSize: 14)),
                                ),
                              ),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.trending_up),
                                  title: Text("Transactions: "),
                                  trailing: Text("$transactionCountDaily", style: TextStyle(fontSize: 14)),
                                  )
                                ),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.leaderboard),
                                  title: Text("Top category: "),
                                  trailing: Text(topCategoryDaily, style: TextStyle(fontSize: 14)),
                                  )
                                ),
                              SizedBox(height: 20),
                              categoryExistingDaily.isNotEmpty 
                              ? PieChart(
                                dataMap: categoryExistingDaily,
                                legendOptions: LegendOptions(legendPosition: LegendPosition.bottom))
                              : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text("No data for pie chart.",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), 
                              )
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
  Future<void> _selectDate() async {
  DateTime? _picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(), 
    firstDate: DateTime(2000), 
    lastDate: DateTime(2100),
    builder: (context, child) { //date picker's theme
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ), 
        child: child!
        );
      }
    );

    if(_picked != null) {
      setState(() {
        _dateController.text = _picked.toString().split(" ")[0];
      });
    }
  } 
}