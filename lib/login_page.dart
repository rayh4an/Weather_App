import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'styles.dart'; 
import 'home_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegistering = false;

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegistering) {
        // Register
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _showConfirmation('Registration successful! Please log in.');
        setState(() => _isRegistering = false);
      } else {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Something went wrong');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentTan,
      appBar: AppBar(
        title: Text(_isRegistering ? 'Register' : 'Welcome Back!'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isRegistering ? 'Register' : 'Login',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login'
                          : 'No account? Register',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
