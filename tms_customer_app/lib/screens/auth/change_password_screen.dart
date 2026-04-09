import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.changePassword(_current.text, _new.text);
      if (mounted) {
        final msg = 'change_pwd_success'.tr();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      String text = 'change_pwd_failed'.tr();
      String code = '';
      try {
        // If AuthException or server message, show server-provided message
        if (e is Exception && e.toString().isNotEmpty) {
          text = e.toString();
        }
        // Try to detect unauthenticated error and prompt re-login
        code = e is Exception ? e.toString().toLowerCase() : '';
      } catch (_) {}

      // If session invalid, show dialog offering to re-login
      if (code.contains('unauthenticated') || text.toLowerCase().contains('session') || text.toLowerCase().contains('expired')) {
        if (!mounted) return;
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('session_expired'.tr()),
            content: Text('please_login_again'.tr()),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('cancel'.tr())),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('login'.tr())),
            ],
          ),
        );
        if (retry == true) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.logout();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
          return;
        }
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
      // If server reports user not found, force logout to recover state
      if (text.toLowerCase().contains('user not found')) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('change_password'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                  controller: _current,
                  decoration:
                      InputDecoration(labelText: 'current_password'.tr()),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'required'.tr() : null),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _new,
                  decoration: InputDecoration(labelText: 'new_password'.tr()),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                    ? 'passwordTooShort'.tr()
                    : null),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirm,
                  decoration:
                    InputDecoration(labelText: 'confirm_new_password'.tr()),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty
                    ? 'required'.tr()
                    : (v != _new.text ? 'passwords_do_not_match'.tr() : null)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text('change_password'.tr())),
            ],
          ),
        ),
      ),
    );
  }
}
