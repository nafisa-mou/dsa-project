import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;

  // Registration specifics
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();
  final _batchController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);
    bool success = false;

    if (_isRegistering) {
      success = await auth.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _deptController.text.trim(),
        batch: _batchController.text.trim(),
      );
    } else {
      success = await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (!success) {
      final error = ref.read(authProvider).errorMessage;
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.85),
              AppTheme.secondaryColor.withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO & HEADER
                      const Icon(Icons.directions_bus, size: 64, color: AppTheme.primaryColor),
                      const SizedBox(height: AppTheme.smallSpacing),
                      Text(
                        _isRegistering ? 'Create Student Account' : 'Smart Bus Student',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.largeSpacing),

                      // FIELDS
                      if (_isRegistering) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter your phone number' : null,
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        TextFormField(
                          controller: _deptController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.school),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter department' : null,
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        TextFormField(
                          controller: _batchController,
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            prefixIcon: Icon(Icons.group),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Please enter batch ID' : null,
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter email';
                          if (!val.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter password';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.largeSpacing),

                      // SUBMIT BUTTON
                      if (authState.isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(_isRegistering ? 'Register' : 'Login'),
                        ),

                      const SizedBox(height: AppTheme.mediumSpacing),

                      // TOGGLE MODE
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                          });
                        },
                        child: Text(
                          _isRegistering ? 'Already have an account? Login' : 'Need an account? Register',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
}
