import 'package:flutter/material.dart';
import 'package:btcuoiky/TaskManager/model/User.dart';
import 'package:btcuoiky/TaskManager/db/UserDatabaseHelper.dart';
import 'package:btcuoiky/TaskManager/view/Authentication/LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (password != confirmPassword) {
        _showErrorDialog('Mật khẩu xác nhận không khớp!');
        return;
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        email: email,
        avatar: null,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final result = await UserDatabaseHelper.instance.createUser(user);

      if (result > 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        _showErrorDialog('Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.shade600.withOpacity(0.9),
                              Colors.blue.shade500.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade900.withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Tạo tài khoản mới!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.blue.shade900.withOpacity(0.3),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Vui lòng nhập thông tin đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 32),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Tên người dùng',
                                    hintText: 'Nhập tên người dùng',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Colors.white.withOpacity(0.15),
                                    filled: true,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập tên người dùng';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Nhập email của bạn',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.email, color: Colors.white70),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Colors.white.withOpacity(0.15),
                                    filled: true,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    hintText: 'Nhập mật khẩu',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.lock, color: Colors.white70),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Colors.white.withOpacity(0.15),
                                    filled: true,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    hintText: 'Nhập lại mật khẩu',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.lock, color: Colors.white70),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Colors.white.withOpacity(0.15),
                                    filled: true,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.blue.shade900,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.blue.shade900.withOpacity(0.5),
                                  ),
                                  onPressed: _handleRegister,
                                  child: Text(
                                    'Đăng ký',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Đã có tài khoản? ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Đăng nhập',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}