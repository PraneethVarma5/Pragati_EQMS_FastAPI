import 'package:flutter/material.dart';
import '../../../models/dcc/dcc_user.dart';
import '../../../services/dcc/dcc_user_service.dart';

class AddDccUserScreen extends StatefulWidget {
  const AddDccUserScreen({super.key});

  @override
  State<AddDccUserScreen> createState() => _AddDccUserScreenState();
}

class _AddDccUserScreenState extends State<AddDccUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _hodNameController = TextEditingController();
  final _hodEmailController = TextEditingController();

  String _userType = 'USER';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _hodNameController.dispose();
    _hodEmailController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();

    final alreadyExists = await DccUserService.emailExists(email);

    if (alreadyExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An account with this email already exists.',
          ),
        ),
      );

      return;
    }

    final user = DccUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: email,
      role: _userType,
      hodName: _hodNameController.text.trim(),
      hodEmail: _hodEmailController.text.trim().toLowerCase(),
      password: 'welcome123',
    );

    await DccUserService.addUser(user);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully. Temporary password: welcome123',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = _userType == 'USER';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Add Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE4E8F0),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 25),

                    _label('Name'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        'Enter full name',
                        Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _label('Email'),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Enter email address',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the email';
                        }

                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _label('User Type'),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: _userType,
                      decoration: _inputDecoration(
                        'Select user type',
                        Icons.badge_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'USER',
                          child: Text('User'),
                        ),
                        DropdownMenuItem(
                          value: 'HOD',
                          child: Text('HOD'),
                        ),
                        DropdownMenuItem(
                          value: 'DCC',
                          child: Text('DCC'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _userType = value;

                          if (_userType != 'USER') {
                            _hodNameController.clear();
                            _hodEmailController.clear();
                          }
                        });
                      },
                    ),

                    if (isUser) ...[
                      const SizedBox(height: 30),

                      const Text(
                        'Assigned HOD',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _label('HOD Name'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _hodNameController,
                        decoration: _inputDecoration(
                          'Enter HOD name',
                          Icons.supervisor_account_outlined,
                        ),
                        validator: (value) {
                          if (!isUser) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the HOD name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _label('HOD Email'),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _hodEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          'Enter HOD email',
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (!isUser) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the HOD email';
                          }

                          if (!value.contains('@')) {
                            return 'Please enter a valid HOD email';
                          }

                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _createUser,
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                        ),
                        label: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3155D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF172033),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF3155D9),
          width: 1.5,
        ),
      ),
    );
  }
}