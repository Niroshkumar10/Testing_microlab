import 'package:flutter/material.dart';
import 'services/api_service.dart';
import '../utils/storage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> login(BuildContext context) async {
    if (email.text.isEmpty || pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    if (!email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    var res = await ApiService.login(email.text, pass.text);

    if (!mounted) return;

    setState(() => isLoading = false);

    if (res != null && res["token"] != null) {
      await Storage.saveToken(res["token"]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Login Successful"),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacementNamed(context, "/home");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 10),
            Text("Invalid email or password"),
          ]),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size information
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final isTablet = screenSize.width > 600 && screenSize.width <= 800;
    
    // Responsive sizing
    double horizontalPadding = isWeb ? 48 : (isTablet ? 32 : 24);
    double verticalPadding = isWeb ? 60 : (isTablet ? 48 : 40);
    double maxWidth = isWeb ? 450 : double.infinity;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, 
              vertical: verticalPadding
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Brand Section with responsive sizing
                  Center(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.all(isWeb ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: isWeb ? 60 : 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 40 : 32),
                  
                  // Welcome Text
                  Center(
                    child: Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: isWeb ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Sign in to continue",
                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 56 : 48),

                  // Email Field
                  Text(
                    "Email Address",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.blue),
                      hintText: "example@email.com",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isWeb ? 18 : 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Password Field
                  Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: pass,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => login(context),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      hintText: "Enter your password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isWeb ? 18 : 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Forgot Password and Remember Me Row
                  if (isWeb)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: (value) {},
                              activeColor: Colors.blue,
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        _buildForgotPasswordButton(),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: (value) {},
                              activeColor: Colors.blue,
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildForgotPasswordButton(),
                        ),
                      ],
                    ),
                  
                  SizedBox(height: isWeb ? 32 : 24),

                  // Login Button
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: isWeb ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Divider for web version
                  if (isWeb) ...[
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "or",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Social Login Buttons for web
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.g_mobiledata, color: Colors.red),
                            label: Text("Google"),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.apple, color: Colors.black),
                            label: Text("Apple"),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],

                  // Create Account Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, "/register"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: isWeb ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Footer text for web
                  if (isWeb) ...[
                    SizedBox(height: 32),
                    Center(
                      child: Text(
                        "By signing in, you agree to our Terms of Service\nand Privacy Policy",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reset password link will be sent to your email"),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "OK",
              onPressed: () {},
            ),
          ),
        );
      },
      child: Text(
        "Forgot Password?",
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}