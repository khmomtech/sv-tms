import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.register(
          _username.text.trim(), _email.text.trim(), _password.text);
      if (mounted) {
        final successMsg = 'register_success'.tr();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMsg)));
        Navigator.pop(context);
      }
    } catch (e) {
      final msg = e is Exception ? e.toString() : 'register_failed'.tr();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('register'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                  controller: _username,
                  decoration: InputDecoration(labelText: 'username'.tr()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'required'.tr() : null),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _email,
                  decoration: InputDecoration(labelText: 'email'.tr()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'required'.tr() : null),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _password,
                  decoration: InputDecoration(labelText: 'password'.tr()),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? 'passwordTooShort'.tr()
                      : null),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text('register'.tr())),
            ],
          ),
        ),
      ),
    );
  }
}
