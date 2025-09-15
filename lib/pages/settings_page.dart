import 'dart:convert'; //for converting string in bytes and bytes back in strings (used for hashing)
import 'dart:math'; 
import 'package:crypto/crypto.dart'; //for hashing with SHA-256 algorithm
import 'package:email_validator/email_validator.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; //mobile secured storage
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyapp/transaction_model.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //Keys
  static const String _kEmailKey = 'user_email';
  static const String _kSaltKey = 'user_salt';
  static const String _kHashKey = 'user_hash';
  static const String _kLoggedInKey = 'user_logged_in';

  //UI State variables
  bool _isRegistered = false;
  bool _isLoggedIn = false;
  String? _registeredEmail;

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

  final TextEditingController _changeEmailPwCtrl = TextEditingController();
  final TextEditingController _newEmailCtrl = TextEditingController();

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
    _changeEmailPwCtrl.dispose();
    _newEmailCtrl.dispose();
    super.dispose();
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

  Future<void> _saveCredentials(String email, String password) async {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    await _storage.write(key: _kEmailKey, value: email);
    await _storage.write(key: _kSaltKey, value: salt);
    await _storage.write(key: _kHashKey, value: hash);
    await _storage.write(key: _kLoggedInKey, value: 'true');
  }

  Future<void> _clearCredentials() async {
    await _storage.delete(key: _kEmailKey);
    await _storage.delete(key: _kSaltKey);
    await _storage.delete(key: _kHashKey);
    await _storage.delete(key: _kLoggedInKey);
  }

  Future<void> _setLoggedIn(bool v) async {
    await _storage.write(key: _kLoggedInKey, value: v ? 'true' : 'false');
  }

  Future<void> _loadAuthState() async {
    final email = await _storage.read(key: _kEmailKey);
    final logged = (await _storage.read(key: _kLoggedInKey)) == 'true';
    setState(() {
      _registeredEmail = email;
      _isRegistered = email != null;
      _isLoggedIn = logged && _isRegistered;
    });
  }

  Future<bool> _verifyCredentials(String email, String password) async {
    final storedEmail = await _storage.read(key: _kEmailKey);
    final salt = await _storage.read(key: _kSaltKey);
    final storedHash = await _storage.read(key: _kHashKey);

    if(storedEmail == null || salt == null || storedHash == null) {
      return false;
    }
    if(storedEmail != email) {
      return false;
    }

    final hash = _hashPassword(password, salt);
    return hash == storedHash;
  }

  //Actions
  Future<void> _register() async {
    if(!_registeredFormKey.currentState!.validate()) return;
    final email = _regEmailCtrl.text.trim();
    final password = _regPasswordCtrl.text;
    await _saveCredentials(email, password);
    await _loadAuthState();
    _regPasswordCtrl.clear();
    _regPasswordConfirmCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered and logged in')));
  }

  Future<void> _login() async {
    if(!_loginFormKey.currentState!.validate()) return;
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;
    final ok = await _verifyCredentials(email, password);
    if(ok) {
      await _setLoggedIn(true);
      await _loadAuthState();
      _loginPasswordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login succesful')));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password')));
    }
  }

  Future<void> _logout() async {
    await _setLoggedIn(false);
    await _loadAuthState();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  Future<void> _changePassword() async {
    if(!_changePwFormKey.currentState!.validate()) return;
    final current = _currentPwdCtrl.text;
    final newPw = _newPwdCtrl.text;

    final storedEmail = await _storage.read(key: _kEmailKey);
    if(storedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user found')));
      return;
    }

    final ok = await _verifyCredentials(storedEmail, current);
    if(!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password incorrect')));
      return;
    }

    //save new password (new salt)
    final salt = _generateSalt();
    final hash = _hashPassword(newPw, salt);
    await _storage.write(key: _kSaltKey, value: salt);
    await _storage.write(key: _kHashKey, value: hash);
    _currentPwdCtrl.clear();
    _newPwdCtrl.clear();
    _newPwdConfirmCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
  }

  Future<void> _changeEmail() async {
    final pw = _changeEmailPwCtrl.text;
    final newEmail = _newEmailCtrl.text.trim();
    if(pw.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill both fields')));
      return;
    }
    if(!EmailValidator.validate(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email format')));
      return;
    }
    final storedEmail = await _storage.read(key: _kEmailKey);
    if(storedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user found')));
      return;
    }
    final ok = await _verifyCredentials(storedEmail, pw);
    if(!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password incorrect')));
      return;
    }
    await _storage.write(key: _kEmailKey, value: newEmail);
    _changeEmailPwCtrl.clear();
    _newEmailCtrl.clear();
    await _loadAuthState();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated')));
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool> (
      context: context,
      builder: (ctx) => AlertDialog( 
        title: const Text('Delete account?'),
        content: const Text('This will remove stored credentials. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if(confirmed == true) {
      await _clearCredentials();
      await _loadAuthState();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
    }
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

            if(!_isRegistered) ...[
              //if not registered
              Text('Create an account (stored locally): '),
              SizedBox(height: 8),
              Form(
                key: _registeredFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _regEmailCtrl,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Email required' : (!EmailValidator.validate(v) ? 'Invalid email' : null),
                      keyboardType: TextInputType.emailAddress,
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
                      validator: (v) => v != _regPasswordCtrl.text ? 'Passwords do not match' : null,
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _register, 
                      child: Text('Register')
                    ),
                  ],
                ),
              ),
            ] else ...[
              //registered
              Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(_registeredEmail ?? '-'),
                  subtitle: Text(_isLoggedIn ? 'Logged in' : 'Logged out'),
                ),
              ),
              SizedBox(height: 12),

              //if logged out - show login form
              if(!_isLoggedIn) ... [
                Text('Sign in: '),
                const SizedBox(height: 8),
                Form(
                  key: _loginFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _loginEmailCtrl..text = _registeredEmail ?? '',
                        decoration: InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
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
                        child: Text('login')
                      ),
                    ],
                  ),
                ),
              ] else ...[
                //Logged in - show actions
                ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  onPressed: _logout,
                  //style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                SizedBox(height: 12), 

                //change password
                ExpansionTile(
                  leading: Icon(Icons.lock),
                  title: Text('Change password'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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
                              decoration: InputDecoration(labelText: 'New password'),
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _newPwdConfirmCtrl,
                              decoration: const InputDecoration(labelText: 'Confirm new password'),
                              obscureText: true,
                              validator: (v) => v != _newPwdCtrl.text ? 'Passwords do not match' : null,
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
                SizedBox(height: 12),
                //change email
                ExpansionTile(
                  leading: Icon(Icons.email),
                  title: Text('Change email'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _changeEmailPwCtrl,
                            decoration: InputDecoration(labelText: 'Current password'),
                            obscureText: true,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _newEmailCtrl,
                            decoration: InputDecoration(labelText: 'New email'),
                            keyboardType: TextInputType.emailAddress,
                            ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _changeEmail, 
                            child: Text('Update email')
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Delete account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
                  onPressed: _deleteAccount,
                ),
              ],
            ],

            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 8),
            Text('Other settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
            //more settings coming soon
            SizedBox(height: 8),
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