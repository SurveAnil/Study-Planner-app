import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  /// Show an error dialog to the user
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign-In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle Google Sign-In process with comprehensive error handling
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Sign in with Google and Firebase
      print('📱 Initiating Google Sign-In...');
      final firebaseUser = await _authService.signInWithGoogle();

      if (firebaseUser == null) {
        throw Exception('Failed to authenticate with Google');
      }

      print('✅ Firebase authentication successful: ${firebaseUser.email}');

      // Step 2: Check if user exists in backend
      print('🔍 Checking backend user...');
      User? backendUser = await _apiService.getUser(firebaseUser.uid);

      if (backendUser == null) {
        // Step 3: Create user in backend if doesn't exist
        print('👤 Creating new user in backend...');
        backendUser = await _apiService.createUser(
          firebaseUser.displayName ?? 'User',
          firebaseUser.email ?? '',
          firebaseUser.uid,
        );
        print('✅ User created successfully in backend');
      } else {
        print('✅ User already exists in backend');
      }

      if (!mounted) return;

      // Step 4: Navigate to dashboard
      print('🚀 Navigating to dashboard...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(user: backendUser!),
        ),
      );
    } on Exception catch (e) {
      // Handle authentication errors
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('❌ Sign-in error: $errorMessage');

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Handle unexpected errors
      final errorMessage = 'An unexpected error occurred: $e';
      print('❌ Unexpected error: $errorMessage');

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        _showErrorDialog(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Habit Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade400,
                  ),
                  child: Icon(Icons.trending_up, size: 64, color: Colors.white),
                ),
                SizedBox(height: 32),
                // Title
                Text(
                  'Habit Tracker',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                // Subtitle
                Text(
                  'Build better habits, one day at a time',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                // Error Message (if any)
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) SizedBox(height: 24),
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.login),
                    label: Text(
                      _isLoading ? 'Signing In...' : 'Sign in with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Info Text
                Text(
                  'Secure authentication powered by Firebase',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
