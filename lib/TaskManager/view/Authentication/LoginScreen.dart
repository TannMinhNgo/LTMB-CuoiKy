import 'package:flutter/material.dart';
import 'package:btcuoiky/TaskManager/view/Task/TaskListScreen.dart';
import 'package:btcuoiky/TaskManager/model/User.dart';
import 'package:btcuoiky/TaskManager/db/UserDatabaseHelper.dart';
import 'package:btcuoiky/TaskManager/view/Authentication/RegisterScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final user = await UserDatabaseHelper.instance
            .getUserByEmailAndPassword(email, password);

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          await prefs.setString('username', user.username);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TaskListScreen(currentUserId: user.id!),
            ),
          );
        } else {
          _showLoginErrorDialog();
        }
      } catch (e) {
        _showLoginErrorDialog(message: 'Đã xảy ra lỗi: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLoginErrorDialog({String? message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi đăng nhập'),
          content: Text(message ??
              'Thông tin đăng nhập không chính xác. Vui lòng kiểm tra lại.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                              children: [
                                Text(
                                  'Đăng nhập',
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
                                ),
                                SizedBox(height: 24),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Vui Lòng Nhập Email',
                                    labelStyle: TextStyle(color: Colors.white70),
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
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.lock, color: Colors.white70),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
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
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue.shade900,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.blue.shade900.withOpacity(0.5),
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                        : Text(
                                      'ĐĂNG NHẬP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Chưa có tài khoản? ',
                                      style: TextStyle(color: Colors.white70),
                                      children: [
                                        TextSpan(
                                          text: 'Đăng ký ngay',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
