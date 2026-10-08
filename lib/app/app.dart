import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../development/component_catalog_page.dart';

class AgendaiFisioApp extends StatelessWidget {
  const AgendaiFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaiFisio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ComponentCatalogPage(),
    );
  }
}
