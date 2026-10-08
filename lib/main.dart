import 'package:flutter/material.dart';

import 'Pages/login_page.dart';

void main() {
  runApp(const AgendaiFisioApp());
}

class AgendaiFisioApp extends StatelessWidget {
  const AgendaiFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendai Fisio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B87)),
        scaffoldBackgroundColor: const Color(0xFFF4F8FA),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
