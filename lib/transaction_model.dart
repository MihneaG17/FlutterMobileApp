import 'package:hive/hive.dart';

part 'transaction_model.g.dart'; 

//template used for saving transaction details

@HiveType(typeId: 0) 
class Transaction extends HiveObject {
  @HiveField(0) 
  late double amount;

  @HiveField(1)
  late String category;

  @HiveField(2)
  late DateTime date;
}