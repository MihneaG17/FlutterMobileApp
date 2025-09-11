import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart'; //for pie charts
import 'package:month_year_picker/month_year_picker.dart';
import 'package:moneyapp/transaction_model.dart';

class StatsPage extends StatefulWidget {
  StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _dropdownValue='daily';
  TextEditingController _dateController = TextEditingController();
  TextEditingController _dateControllerMonthly = TextEditingController();

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
      _dateControllerMonthly.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Theme.of(context).primaryColor;

    final box = Hive.box<Transaction>('transactions');
    final allTx = box.values.toList();
    
    DateTime selectedDate = DateTime.now();

    if(_dropdownValue == 'monthly')
    {
      if(_dateControllerMonthly.text.isEmpty) {
        final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        _dateControllerMonthly.text = firstOfMonth.toIso8601String().split('T')[0];
        selectedDate = firstOfMonth;
      }
      else {
        try {
          selectedDate=DateTime.parse(_dateControllerMonthly.text);
        } catch (e) {
          //fallback in case of invalid format
          selectedDate=DateTime.now();
          final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
          _dateControllerMonthly.text = firstOfMonth.toIso8601String().split('T')[0];
        }
      }
    } else if(_dropdownValue == 'daily') {
      try {
        selectedDate = DateTime.parse(_dateController.text);
      } catch (e) { 
        selectedDate = DateTime.now();
        _dateController.text = selectedDate.toString().split(" ")[0];
      }
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
                  Container( 
                    padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(items:  
                        [
                          DropdownMenuItem(value: "daily", child: Text("daily")),
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
              box.isEmpty ? 
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
                  : _buildStatsContent(_dropdownValue, context, box, allTx, selectedDate),
          ],
        ),
    );
  }

  Widget _buildStatsContent(String value, BuildContext context, box, allTx, DateTime selectedDate) {
    switch(value) {
        case "daily":
          return dailyStats(context, box, allTx, selectedDate);
        case "monthly":
          return monthlyStats(context, box, allTx, selectedDate);
        case "yearly": 
          return Placeholder();
        default: 
          return Placeholder();
      }
  }

  Column dailyStats(BuildContext context, final box, final allTx, DateTime selectedDate) {
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
    return Column(
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
                      leading: Icon(Icons.calculate),
                      title: Text("Average spent: "),
                      trailing: Text("${totalSpentDaily/1} USD", style: TextStyle(fontSize: 14)), //Average spent section for "daily" option will be the same as Total spent
                      )
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
                    dataMap: categoryTotalsDaily,
                    legendOptions: LegendOptions(legendPosition: LegendPosition.bottom),
                    chartValuesOptions: ChartValuesOptions(
                        showChartValuesInPercentage: true,
                      ),)
                  : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("No data for pie chart.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), 
                  ),
                  SizedBox(height: 20),
                  categoryExistingDaily.isNotEmpty 
                  ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Category Breakdown",  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          SizedBox(height: 10),
                          ListView.builder(  
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: categoryTotalsDaily.length,
                        itemBuilder: (context, index) {
                          final entry = categoryTotalsDaily.entries.elementAt(index);
                          final percent = totalSpentDaily > 0
                              ? (entry.value / totalSpentDaily * 100).toStringAsFixed(1)
                              : "0";
                          return ListTile(
                            leading: Icon(Icons.label),
                            title: Text(entry.key),
                            trailing: Text(
                              "${entry.value.toStringAsFixed(2)} USD ($percent%)",
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ) 
                    ],
                  )
                  : SizedBox.shrink(),
                ],
              ),
            )
          ],
        );
      }

  // ...existing code...
Builder monthlyStats(BuildContext context, final box, final allTx, DateTime selectedDate) {
  return Builder(
    builder: (pickerContext) => Column(
      children: [
        Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        SizedBox(height: 10),
        Text("Select a month: ", style: TextStyle(fontSize: 14)),
        SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 170,
            child: TextField(
              controller: _dateControllerMonthly,
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
              onTap: () async {
                final picked = await showMonthYearPicker(
                  context: pickerContext, // <-- use pickerContext here!
                  initialDate: selectedDate,
                  firstDate: DateTime(2000), 
                  lastDate: DateTime(2100)
                );
                if(picked!=null) {
                  setState(() {
                   final normalized = DateTime(picked.year, picked.month, 1);
                    _dateControllerMonthly.text = normalized.toIso8601String().split("T")[0];
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
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