import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
                          DropdownMenuItem(value: "amount", child: Text("amount")),
                          DropdownMenuItem(value: "date", child: Text("date")),
                        ], 
                        value: _dropdownValue,
                        onChanged: dropDownCallBack,
                        iconEnabledColor: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
    );
  }
}