import 'package:hive/hive.dart';

part 'user_model.g.dart'; // This will be auto-generated

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String username;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String password;

  UserModel({required this.fullName, required this.username, required this.email, required this.phone, required this.password});
}
