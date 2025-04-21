import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'login_page.dart';
import 'user_model.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      var box = Hive.box<UserModel>('users');

      if (box.containsKey(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User already exists! Try logging in."), backgroundColor: Colors.orange),
        );
        return;
      }

      UserModel newUser = UserModel(
        fullName: _fullNameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      box.put(_emailController.text, newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful!"), backgroundColor: Colors.green),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[900]!, Colors.teal[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: EdgeInsets.symmetric(horizontal: 30),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        "Create Account",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(_fullNameController, "Full Name", Icons.person),
                      SizedBox(height: 10),
                      _buildTextField(_usernameController, "Username", Icons.account_circle),
                      SizedBox(height: 10),
                      _buildTextField(_emailController, "Email", Icons.email, validator: _validateEmail),
                      SizedBox(height: 10),
                      _buildTextField(_phoneController, "Phone Number", Icons.phone, validator: _validatePhone),
                      SizedBox(height: 10),
                      _buildTextField(_passwordController, "Password", Icons.lock, obscureText: true, validator: _validatePassword),
                      SizedBox(height: 10),
                      _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock, obscureText: true, validator: _validateConfirmPassword),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                          elevation: 5,
                        ),
                        child: Text("Register", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal[800]),
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal[800]!),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator ?? (value) => value!.isEmpty ? "$hint is required" : null,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || !value.contains("@gmail.com")) {
      return "Enter a valid Gmail address";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return "Passwords do not match!";
    }
    return null;
  }
}
