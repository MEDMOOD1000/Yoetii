import 'package:flutter/material.dart';

/// Content slot retained inside Mornye's original animated shell.
class EmptyContent extends StatelessWidget {
  const EmptyContent({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    ),
  );
}
