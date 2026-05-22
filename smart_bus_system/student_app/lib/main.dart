import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/student_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: SmartBusStudentApp()));
}

class SmartBusStudentApp extends ConsumerWidget {
  const SmartBusStudentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Bus - Student',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const StudentAuthWrapper(),
    );
  }
}

class StudentAuthWrapper extends StatelessWidget {
  const StudentAuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Add auth state check
    return const StudentHomeScreen();
  }
}
