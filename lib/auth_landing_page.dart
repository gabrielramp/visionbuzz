import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'auth_provider.dart';

class AuthLandingPage extends StatefulWidget {
  final String fbToken;
  
  AuthLandingPage({required this.fbToken});
  
  @override
  _AuthLandingPageState createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AuthProvider authProvider;
  bool isLoading = false;
  String errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App logo and title
            Container(
              padding: EdgeInsets.only(top: 50, bottom: 30),
              child: Column(
                children: [
                  Icon(
                    Icons.visibility,
                    color: colorScheme.primary,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'VisionBuzz',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect and communicate with your device',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar for Login/Register
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(text: 'LOGIN'),
                Tab(text: 'REGISTER'),
              ],
            ),
            
            // Error message if any
            if (errorMessage.isNotEmpty)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            
            // Tab content for Login/Register
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Login Tab
                  LoginForm(
                    onSubmit: _handleLogin,
                    isLoading: isLoading,
                  ),
                  
                  // Register Tab
                  RegisterForm(
                    onSubmit: _handleRegister,
                    fbToken: widget.fbToken,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Handle login submission
  Future<void> _handleLogin(String username, String password) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final response = await http.post(
        Uri.parse('http://137.184.156.253/api/v1/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          <String, String>{'username': username, 'password': password}
        ),
      );
      
      setState(() {
        isLoading = false;
      });
      
      if (response.statusCode == 200) {
        print("Login PASS");
        var responseData = jsonDecode(response.body);
        var accessToken = responseData['access_token'];
        print("Token = $accessToken");
        
        // Login with the token and provide username
        await authProvider.login(accessToken, username: username);
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Invalid username or password";
        });
      } else {
        setState(() {
          errorMessage = "Login failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }
  
  // Handle registration submission
  Future<void> _handleRegister(String username, String password) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final response = await http.post(
        Uri.parse('http://137.184.156.253/api/v1/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          <String, String>{
            'username': username, 
            'password': password, 
            'firebase_token': widget.fbToken
          }
        ),
      );
      
      setState(() {
        isLoading = false;
      });
      
      if (response.statusCode == 200) {
        print("REGISTER PASS");
        var responseData = jsonDecode(response.body);
        var accessToken = responseData['access_token'];
        print("Token = $accessToken");
        
        // Login with the token and provide username
        await authProvider.login(accessToken, username: username);
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Username is already taken";
        });
      } else {
        setState(() {
          errorMessage = "Registration failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }
}

// Login Form Component
class LoginForm extends StatefulWidget {
  final Function(String, String) onSubmit;
  final bool isLoading;
  
  LoginForm({required this.onSubmit, required this.isLoading});
  
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            
            // Login button
            ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit(
                          _usernameController.text,
                          _passwordController.text,
                        );
                      }
                    },
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('LOGIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Register Form Component
class RegisterForm extends StatefulWidget {
  final Function(String, String) onSubmit;
  final String fbToken;
  final bool isLoading;
  
  RegisterForm({
    required this.onSubmit, 
    required this.fbToken,
    required this.isLoading,
  });
  
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please choose a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Confirm Password field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            
            // Firebase token info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your device will be registered with your account',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Register button
            ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit(
                          _usernameController.text,
                          _passwordController.text,
                        );
                      }
                    },
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('REGISTER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
