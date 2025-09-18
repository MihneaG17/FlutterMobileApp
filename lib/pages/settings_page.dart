import 'dart:convert'; //for converting string in bytes and bytes back in strings (used for hashing)
import 'dart:math'; 
import 'package:crypto/crypto.dart'; //for hashing with SHA-256 algorithm
import 'package:email_validator/email_validator.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; //mobile secured storage
import 'package:provider/provider.dart';
import 'package:moneyapp/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyapp/transaction_model.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //Keys
  static const String _kAccountsKey = 'user_accounts'; //list with email, hash & salt
  static const String _kLoggedInKey = 'user_logged_in'; //logged in email

  //UI State variables
  bool _isLoggedIn = false;
  String? _loggedEmail;
  List<Map<String, String>> _accounts = [];

  //Forms
  final _registeredFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final _changePwFormKey = GlobalKey<FormState>();

  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regPasswordCtrl = TextEditingController();
  final TextEditingController _regPasswordConfirmCtrl = TextEditingController();

  final TextEditingController _loginEmailCtrl = TextEditingController();
  final TextEditingController _loginPasswordCtrl = TextEditingController();

  final TextEditingController _currentPwdCtrl = TextEditingController();
  final TextEditingController _newPwdCtrl = TextEditingController();
  final TextEditingController _newPwdConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  @override
  void dispose() {
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regPasswordConfirmCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _newPwdConfirmCtrl.dispose();
    super.dispose();
  }

  //Export transactions to PDF file
  Future<void> exportTransactionsToPdf() async {
      final box = Hive.box<Transaction>('transactions');
      final transactions = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Transactions Export', 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),

                ...transactions.map((tx) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                        "${tx.date.toString().split(" ")[0]} - ${tx.category} - ${tx.amount.toStringAsFixed(2)} USD",
                        style: const pw.TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ]
            );
          }
        )
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/transactions_export.pdf");
      await file.writeAsBytes(await pdf.save());

      //open file after export
      await OpenFile.open(file.path);
  }

  //Storage helpers
  String _generateSalt([int len = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(len, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveAccounts() async {
    final data = jsonEncode(_accounts);
    await _storage.write(key: _kAccountsKey, value: data);
  }

  Future<void> _loadAuthState() async {
    final accStr = await _storage.read(key: _kAccountsKey);
    final loggedEmail = await _storage.read(key: _kLoggedInKey);

    List<Map<String, String>> accList = [];
    if(accStr != null) {
      final decoded = jsonDecode(accStr) as List<dynamic>;
      accList = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    setState(() {
      _accounts = accList;
      _loggedEmail = loggedEmail;
      _isLoggedIn = loggedEmail != null;
    });
  }

  //Actions
  Future<void> _register() async {
    if(!_registeredFormKey.currentState!.validate()) return;

    final email = _regEmailCtrl.text.trim();
    final password = _regPasswordCtrl.text;

    if(_accounts.any((acc) => acc['email'] == email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email already registered')));
      return;
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    _accounts.add({'email': email, 'salt': salt, 'hash': hash});
    await _saveAccounts();

    //log in after register
    await _storage.write(key: _kLoggedInKey, value: email);
    await _loadAuthState();

    _regEmailCtrl.clear();
    _regPasswordCtrl.clear();
    _regPasswordConfirmCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created and logged in')));
  }

  Future<void> _login() async {
    if(!_loginFormKey.currentState!.validate()) return;

    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;

    final acc = _accounts.firstWhere((acc) => acc['email'] == email, orElse: () => {});
    if (acc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No account with this email')));
      return;
    }

    final hash = _hashPassword(password, acc['salt']!);
    if(hash != acc['hash']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password')));
      return;
    }

    await _storage.write(key: _kLoggedInKey, value: email);
    await _loadAuthState();

    _loginPasswordCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
  }

  Future<void> _logout() async {
    await _storage.delete(key: _kLoggedInKey);
    await _loadAuthState();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  Future<void> _changePassword() async {
    if(!_changePwFormKey.currentState!.validate()) return;

    final current = _currentPwdCtrl.text;
    final newPw = _newPwdCtrl.text;

    final acc = _accounts.firstWhere((a) => a['email'] == _loggedEmail, orElse: () => {});
    if (acc.isEmpty) return;

    final currentHash = _hashPassword(current, acc['salt']!);
    if(currentHash != acc['hash'])
    {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password incorrect')));
      return;
    }

    //save new password (and new salt)
    final newSalt = _generateSalt();
    final newHash = _hashPassword(newPw, newSalt);

    acc['salt'] = newSalt;
    acc['hash'] = newHash;

    await _saveAccounts();
    _currentPwdCtrl.clear();
    _newPwdCtrl.clear();
    _newPwdConfirmCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
  }

  Future<void> _deleteAccount() async {
    final pwCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your current password to confirm.'),
              SizedBox(height: 12),
              TextField(
                controller: pwCtrl,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
          ],
        )
      );

      if(confirmed != true) return;

      final accountsJson = await _storage.read(key: _kAccountsKey);
      if(accountsJson == null) return;

      final accounts = List<Map<String, dynamic>>.from(jsonDecode(accountsJson));

      final currentAcc = accounts.firstWhere(
        (acc) => acc['email'] == _loggedEmail,
        orElse: () => {},
      );

      if(currentAcc.isEmpty || !currentAcc.containsKey('salt') || !currentAcc.containsKey('hash')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No account found')));
        return;
      }

      final ok = _hashPassword(pwCtrl.text, currentAcc['salt']) == currentAcc['hash'];
      if(!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect password')));
        return;
      }

      accounts.removeWhere((acc) => acc['email'] == _loggedEmail);

      await _storage.write(key: _kAccountsKey, value: jsonEncode(accounts));
      await _logout();
      await _loadAuthState();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            SizedBox(height: 12),

            if(!_isLoggedIn) ...[
              //login / register tabs
              DefaultTabController(
                length: 2, 
                child: Column(
                  children: [
                    TabBar(tabs: [
                      Tab(text: "Sign In"),
                      Tab(text: 'Sign up'),
                    ]),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          //Sign in
                          Form(
                            key: _loginFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _loginEmailCtrl,
                                  decoration: InputDecoration(labelText: 'Email'),
                                  validator: (v) => (v==null || v.isEmpty) ? 'Email required' : null,
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _loginPasswordCtrl,
                                  decoration: InputDecoration(labelText: 'Password'),
                                  obscureText: true,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                                ),
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _login, 
                                  child: Text('Login')
                                ),
                              ],
                            ),
                          ),
                          //Sign up
                          Form(
                            key: _registeredFormKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _regEmailCtrl,
                                  decoration: InputDecoration(labelText: 'Email'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Email required'
                                  : (!EmailValidator.validate(v) ? 'Invalid email' : null),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _regPasswordCtrl,
                                  decoration: InputDecoration(labelText: 'Password'),
                                  obscureText: true,
                                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _regPasswordConfirmCtrl,
                                  decoration: InputDecoration(labelText: 'Confirm password'),
                                  obscureText: true,
                                  validator: (v) => (v != _regPasswordCtrl.text) ? 'Password do not match' : null,
                                ),
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _register, 
                                  child: Text('Register')
                                ),
                              ],
                            ),
                          ),
                        ]),
                    )
                  ],
                )
              ),
            ] else ...[
              //logged in
              Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if(value == 'Logout') {
                        _logout();
                      } else if (value == 'Delete') {
                        _deleteAccount();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'Logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete account'),
                          ],
                        ),
                      ),
                    ]
                  ),
                  title: Text(_loggedEmail ?? '-'),
                  subtitle: Text(('Logged in'),
                  ),
                ),
              ),
              SizedBox(height: 12),

              ExpansionTile(
                leading: Icon(Icons.lock),
                title: Text('Change password'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Form(
                      key: _changePwFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentPwdCtrl,
                            decoration: InputDecoration(labelText: 'Current password'),
                            obscureText: true,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _newPwdCtrl,
                            decoration:
                                InputDecoration(labelText: 'New password'),
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? 'At least 6 characters'
                                    : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _newPwdConfirmCtrl,
                            decoration: InputDecoration(
                                labelText: 'Confirm new password'),
                            obscureText: true,
                            validator: (v) =>
                                v != _newPwdCtrl.text
                                    ? 'Passwords do not match'
                                    : null,
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _changePassword, 
                            child: Text('Save new password')
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 8),
            Text('Other settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dark theme', style: TextStyle(fontSize: 16)),
                SizedBox(
                    width: 60,
                    child: Switch(
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (value) => context.read<ThemeProvider>().toggleTheme(value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Clear all transactions', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Clear transactions?'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Are you sure you want to clear all the transactions history? This action cannot be undone.'),
                          SizedBox(height: 12),
                          ],
                        ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Clear', style: TextStyle(color: Colors.red))),
                        ],
                      )
                    );
                    if(confirmed == true) {
                        try {
                          final box = Hive.box<Transaction>('transactions');
                          await box.clear();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All transactions cleared.')));
                          if(mounted) {
                            setState(() {}); //forces the UI to rebuild
                          }
                        }
                        catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing transactions: $e')));
                        }
                    }
                  }, 
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text('Export transactions as PDF', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.picture_as_pdf),
                    onPressed: () async {
                      await exportTransactionsToPdf();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported transactions as PDF')));
                    },
                  )
              ],
            ),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              subtitle: Text('App version 1.0.0'),
              onTap: () => showAboutDialog(
                context: context, 
                applicationName: 'MoneyApp',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Dobrin Mihnea-Gabriel'
              ),
            )
          ],
        ),
      ),
    );
  }
}