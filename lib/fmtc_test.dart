import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Yeni sürümde store içeriğini temizlemek için:

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('FMTC yeni API ile başarıyla başlatıldı.'),
        ),
      ),
    );
  }
}
