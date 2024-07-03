import 'package:flutter/material.dart';
import 'package:creategitcopy/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Omegle Clone',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const Omegle(),
    );
  }
}
