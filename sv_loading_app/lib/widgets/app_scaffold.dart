import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppScaffold extends StatelessWidget {
  final String titleKey;
  final Widget child;
  final List<Widget>? actions;

  const AppScaffold(
      {super.key, required this.titleKey, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleKey.tr()),
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }
}
