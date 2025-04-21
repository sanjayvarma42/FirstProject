import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user_model.dart';
import 'login_page.dart';
import 'homepage_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('settings'); // Box for login session

  var settingsBox = Hive.box('settings');
  String? loggedInUserEmail = settingsBox.get('loggedInUser');

  runApp(MyApp(loggedInUserEmail: loggedInUserEmail));
}

class MyApp extends StatelessWidget {
  final String? loggedInUserEmail;

  MyApp({this.loggedInUserEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: loggedInUserEmail != null ? HomePage(email: loggedInUserEmail!) : LoginPage(),
    );
  }
}
