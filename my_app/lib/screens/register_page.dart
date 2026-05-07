import 'package:flutter/material.dart';
import 'services/api_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  Future<void> register(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    var res = await ApiService.register(
      name.text,
      email.text,
      pass.text,
    );

    setState(() {
      isLoading = false;
    });

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, "/login");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final isWeb = screenSize.width > 800;
    final isTablet =
        screenSize.width > 600 && screenSize.width <= 800;

    double horizontalPadding =
        isWeb ? 48 : (isTablet ? 32 : 24);

    double verticalPadding =
        isWeb ? 40 : (isTablet ? 35 : 30);

    double maxWidth =
        isWeb ? 500 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [
                  if (isWeb)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 24,
                      ),

                      child: Row(
                        children: [
                          _buildBackButton(),
                          const Spacer(),
                        ],
                      ),
                    )
                  else
                    _buildBackButton(),

                  if (!isWeb)
                    const SizedBox(height: 20),

                  Center(
                    child: Container(
                      padding: EdgeInsets.all(
                        isWeb ? 24 : 20,
                      ),

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade400,
                          ],
                        ),

                        shape: BoxShape.circle,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.green
                                .withOpacity(0.3),

                            blurRadius: 20,

                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: Icon(
                        Icons.person_add_alt_rounded,
                        size: isWeb ? 60 : 50,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: isWeb ? 32 : 24,
                  ),

                  Center(
                    child: Text(
                      "Create Account",

                      style: TextStyle(
                        fontSize: isWeb ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      "Sign up to get started",

                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: isWeb ? 48 : 40,
                  ),

                  _buildTextField(
                    controller: name,
                    label: "Full Name",
                    hint: "John Doe",
                    icon: Icons.person_outline,
                    isWeb: isWeb,
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: email,
                    label: "Email Address",
                    hint: "example@email.com",
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                    isWeb: isWeb,
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: pass,
                    label: "Password",
                    hint: "Enter Password",
                    icon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    isPassword: true,
                    isWeb: isWeb,

                    onPasswordToggle: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: confirmPass,
                    label: "Confirm Password",
                    hint: "Re-enter Password",
                    icon: Icons.lock_outline,
                    obscureText:
                        obscureConfirmPassword,
                    isPassword: true,
                    isWeb: isWeb,

                    onPasswordToggle: () {
                      setState(() {
                        obscureConfirmPassword =
                            !obscureConfirmPassword;
                      });
                    },
                  ),

                  SizedBox(
                    height: isWeb ? 32 : 28,
                  ),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => register(context),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,

                        padding: EdgeInsets.symmetric(
                          vertical:
                              isWeb ? 18 : 16,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        minimumSize:
                            const Size(double.infinity, 50),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Create Account",

                              style: TextStyle(
                                fontSize:
                                    isWeb ? 18 : 16,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Text(
                        "Already have an account? ",

                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize:
                              isWeb ? 15 : 14,
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            "/login",
                          );
                        },

                        child: Text(
                          "Sign In",

                          style: TextStyle(
                            color: Colors.green,
                            fontWeight:
                                FontWeight.bold,

                            fontSize:
                                isWeb ? 15 : 14,
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
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(10),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },

        icon: const Icon(
          Icons.arrow_back_rounded,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
    bool isWeb = false,
    VoidCallback? onPasswordToggle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,

          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Colors.green,
            ),

            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,

                      color: Colors.grey,
                    ),

                    onPressed:
                        onPasswordToggle,
                  )
                : null,

            hintText: hint,

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),

              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),

              borderSide: const BorderSide(
                color: Colors.green,
                width: 2,
              ),
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding:
                EdgeInsets.symmetric(
              vertical: isWeb ? 18 : 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}