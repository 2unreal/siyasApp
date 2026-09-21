import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_environment.dart';
import 'core/services/firebase_service.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize(AppEnvironment.dev);
  runApp(const ProviderScope(child: HouseOfSiyasApp()));
}
