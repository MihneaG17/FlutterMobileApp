import 'package:flutter/material.dart';


class AddTransactionScreen extends StatefulWidget {


  AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final typeItems = ['Food', 'Travel', 'Entertainment', 'Utilities', 'Other'];

  String? selectedValue;
  String textHolder='';

  TextEditingController _dateController = TextEditingController();

  void clickFunctionSaveBtn() {
    setState(() {
      textHolder='Transaction saved';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a transaction'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text('Enter the transaction details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Container(
                child: TextField(
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Amount')
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey, width: 1)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    hint: const Text('Select a category'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    items: typeItems.map((String item) {
                      return DropdownMenuItem<String> (value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue=newValue;
                      });
                    },
                  ))
              ),
              const SizedBox(height: 30),
              Container(
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(), 
                    labelText: 'Date', 
                    suffixIcon: Icon(Icons.calendar_today)),
                onTap: (){
                  _selectDate();
                },
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  //TO-DO - salvare date
                  clickFunctionSaveBtn();
                },
                child: const Text('Save')
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(textHolder, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16), ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(), 
    firstDate: DateTime(2000),
    lastDate: DateTime(2100)
    );

    if(pickedDate != null)
    {
      setState(() {
        _dateController.text=pickedDate.toString().split(" ")[0];
      });
    }
  }
}

