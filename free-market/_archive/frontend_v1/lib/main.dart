import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/customer_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: MaterialApp(
        title: 'نظام الشحن',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textDirection: TextDirection.rtl,
          fontFamily: 'Cairo',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}