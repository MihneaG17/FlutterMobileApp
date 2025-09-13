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
  int _selectedYear = DateTime.now().year;
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
          return yearlyStats(context, box, allTx, selectedDate);
        default: 
          return dailyStats(context, box, allTx, selectedDate);
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
                  onTap: () async {
                      DateTime? picked = await showDatePicker(
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

                  if(picked != null) {
                    setState(() {
                      _dateController.text = picked.toString().split(" ")[0];
                      });
                    }
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

Builder monthlyStats(BuildContext context, final box, final allTx, DateTime selectedDate) {
  final filteredTxMonthly = allTx.where((tx) => 
    tx.date.year == selectedDate.year &&
    tx.date.month == selectedDate.month
  ).toList();

  final totalSpentMonthly = filteredTxMonthly.fold(0.0, (sum, tx) => sum + tx.amount);
  final transactionsCountMonthly = filteredTxMonthly.length;

  final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day; //(...+1, 0) means that in this variable we store the last day of the previos month - trick to get the number of days in the month
  final averageSpentPerDay = totalSpentMonthly / daysInMonth;

  Map<String, double> categoryTotalsMonthly = {};
  Map<String, double> categoryExistingMonthly = {};

  for(var tx in filteredTxMonthly)
  {
    categoryTotalsMonthly[tx.category] = (categoryTotalsMonthly[tx.category] ?? 0)+tx.amount;
    categoryExistingMonthly[tx.category] = (categoryExistingMonthly[tx.category] ?? 0)+1;
  }

  String topCategoryMonthly="None";

  if(categoryTotalsMonthly.isNotEmpty) {
      topCategoryMonthly = categoryTotalsMonthly.entries.reduce((a,b) => a.value > b.value ? a : b).key;
  }


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
                  context: pickerContext, 
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet),
                      title: Text("Total spent: "),
                      trailing: Text("$totalSpentMonthly USD", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.calculate),
                      title: Text("Average spent: "),
                      trailing: Text("${averageSpentPerDay.toStringAsFixed(2)} USD", style: TextStyle(fontSize: 14)), //Average spent section for "daily" option will be the same as Total spent
                      )
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.trending_up),
                      title: Text("Transactions: "),
                      trailing: Text("$transactionsCountMonthly", style: TextStyle(fontSize: 14)),
                      )
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.leaderboard),
                      title: Text("Top category: "),
                      trailing: Text("$topCategoryMonthly", style: TextStyle(fontSize: 14)),
                      )
                    ),
                  SizedBox(height: 20),
                  filteredTxMonthly.isEmpty 
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("No data for pie chart.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), 
                  )
                  : PieChart(
                    dataMap: categoryTotalsMonthly,
                    legendOptions: LegendOptions(legendPosition: LegendPosition.bottom),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValuesInPercentage: true,
                    ),
                    ),
                  SizedBox(height: 20),
                  categoryExistingMonthly.isNotEmpty 
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Category Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: categoryExistingMonthly.length,
                        itemBuilder: (context, index) {
                          final entry = categoryTotalsMonthly.entries.elementAt(index);
                          final percent = totalSpentMonthly > 0 
                            ? (entry.value / totalSpentMonthly * 100).toStringAsFixed(1)
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
                      ),
                    ],
                  )
                  : SizedBox.shrink(),
            ],
          ),
        )
      ],
    ),
  );
}

Builder yearlyStats(BuildContext context, final box, final allTx, DateTime selectedDate) {
  final filteredTxYearly = allTx.where((tx) =>
    tx.date.year == _selectedYear
  ).toList();

  final totalSpentYearly = filteredTxYearly.fold(0.0, (sum, tx) => sum + tx.amount); 
  final transactionsCountYearly = filteredTxYearly.length;

  final averageSpentPerMonth = totalSpentYearly / 12;

  Map<String, double> categoryTotalsYearly = {};
  Map<String, double> categoryExistingYearly = {};

  for(var tx in filteredTxYearly) {
    categoryTotalsYearly[tx.category]=(categoryTotalsYearly[tx.category] ?? 0) + tx.amount;
    categoryExistingYearly[tx.category]=(categoryExistingYearly[tx.category] ?? 0)+1;
  }

  String topCategoryYearly = "None";

  if(categoryTotalsYearly.isNotEmpty) {
      topCategoryYearly = categoryTotalsYearly.entries.reduce((a,b) => a.value > b.value ? a : b).key;
  }
  return Builder(
    builder: (pickerContext) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        SizedBox(height: 10),
        Text("Select a year: ", style: TextStyle(fontSize: 14)),
        SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: Colors.black),
              SizedBox(width: 8),
              Text(
                  "$_selectedYear", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              onPressed: () {
                showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: Text('Select a year'),
                    content: Container(
                      width: 300,
                      height: 300,
                      child: YearPicker(
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100), 
                        selectedDate: DateTime(_selectedYear, 1, 1), 
                        onChanged: (DateTime picked) {
                          setState(() {
                            _selectedYear = picked.year;
                          });
                          Navigator.pop(ctx);
                        }
                      ),
                    ),
                  ),
              );
          }             
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet),
                      title: Text("Total spent: "),
                      trailing: Text("$totalSpentYearly USD", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.calculate),
                      title: Text("Average spent: "),
                      trailing: Text("${averageSpentPerMonth.toStringAsFixed(2)} USD", style: TextStyle(fontSize: 14)), //Average spent section for "daily" option will be the same as Total spent
                      )
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.trending_up),
                      title: Text("Transactions: "),
                      trailing: Text("$transactionsCountYearly", style: TextStyle(fontSize: 14)),
                      )
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.leaderboard),
                      title: Text("Top category: "),
                      trailing: Text("$topCategoryYearly", style: TextStyle(fontSize: 14)),
                      )
                    ),
                    SizedBox(height: 20),
                  filteredTxYearly.isNotEmpty
                  ? PieChart(
                      dataMap: categoryTotalsYearly,
                      legendOptions: LegendOptions(legendPosition: LegendPosition.bottom),
                      chartValuesOptions: ChartValuesOptions(
                      showChartValuesInPercentage: true)
                  )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("No data for pie chart.",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), 
                  ),
                  SizedBox(height: 20),
                  categoryExistingYearly.isNotEmpty
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Category Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: categoryExistingYearly.length,
                        itemBuilder: (context, index) {
                          final entry = categoryTotalsYearly.entries.elementAt(index);
                          final percent = totalSpentYearly > 0
                          ? (entry.value / totalSpentYearly * 100).toStringAsFixed(1)
                          : "0";
                          return ListTile(
                            leading: Icon(Icons.label),
                            title: Text(entry.key),
                            trailing: Text("${entry.value.toStringAsFixed(2)} USD ($percent%)",
                            style: TextStyle(fontSize: 14)),
                          );
                        }
                      ),
                    ],
                  )
                  : SizedBox.shrink(),
                ]
            )    
          )
        ],
      )
    );
  }
}