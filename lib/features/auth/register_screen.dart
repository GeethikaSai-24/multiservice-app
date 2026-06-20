import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Map<String, String> roleLabels = {
    'USER': 'Customer',
    'PROVIDER': 'Provider',
    'DOCTOR': 'Doctor',
  };

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final specialtyController = TextEditingController();
  final serviceController = TextEditingController();
  final hospitalController = TextEditingController();
  final experienceController = TextEditingController();
  final licenseController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String selectedRole = 'USER';

  String _cleanMessage(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().replaceAll(RegExp(r'[\[\]]'), '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.toString().contains('SocketException')) {
      return 'Unable to connect to the backend. Check the Server setting first.';
    }

    return 'Registration failed. Please try again.';
  }

  String? _validateUsername(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 20) {
      return 'Username must be 4-20 characters.';
    }
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(trimmed)) {
      return 'Use only letters, numbers, and underscores.';
    }
    return null;
  }

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value)) {
      return 'Use both uppercase and lowercase letters.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Add at least one number.';
    }
    if (!RegExp(r"""[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\];'`~]""").hasMatch(value)) {
      return 'Add at least one special character.';
    }
    return null;
  }

  String? _validateRoleFields() {
    if (fullNameController.text.trim().isEmpty) {
      return 'Please enter the full name for this registration.';
    }

    if (selectedRole == 'USER') {
      if (addressController.text.trim().isEmpty || cityController.text.trim().isEmpty) {
        return 'Customer address and city are required.';
      }
      return null;
    }

    if (selectedRole == 'PROVIDER') {
      if (specialtyController.text.trim().isEmpty ||
          serviceController.text.trim().isEmpty ||
          experienceController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty ||
          cityController.text.trim().isEmpty) {
        return 'Provider category, service, experience, address, and city are required.';
      }
      return null;
    }

    if (specialtyController.text.trim().isEmpty ||
        hospitalController.text.trim().isEmpty ||
        experienceController.text.trim().isEmpty ||
        licenseController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      return 'Doctor specialization, hospital, experience, license number, and city are required.';
    }
    return null;
  }

  void register() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final usernameError = _validateUsername(usernameController.text);
    if (usernameError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(usernameError)));
      return;
    }

    final emailError = _validateEmail(emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    final passwordError = _validatePassword(passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and confirm password must match')),
      );
      return;
    }

    final roleFieldError = _validateRoleFields();
    if (roleFieldError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(roleFieldError)));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService.register(
        usernameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        phoneController.text.trim(),
        selectedRole,
        {
          'name': fullNameController.text.trim(),
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'service_category': specialtyController.text.trim(),
          'service_name': serviceController.text.trim(),
          'specialization': specialtyController.text.trim(),
          'hospital_name': hospitalController.text.trim(),
          'experience': experienceController.text.trim(),
          'license_number': licenseController.text.trim(),
        },
      );

      if ((response['_statusCode'] ?? 400) == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Registered")),
        );
        Navigator.pop(context);
      } else {
        final message = _cleanMessage(
          response['username'] ??
              response['email'] ??
              response['phone'] ??
              response['password'] ??
              response['detail'] ??
              response['error'],
          'Unable to register',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    specialtyController.dispose();
    serviceController.dispose();
    hospitalController.dispose();
    experienceController.dispose();
    licenseController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _helperText(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }

  Widget _roleSpecificFields() {
    if (selectedRole == 'USER') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customer Details'),
          TextField(
            controller: fullNameController,
            decoration: inputStyle('Full Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: addressController,
            decoration: inputStyle('Address'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cityController,
            decoration: inputStyle('City'),
          ),
          _helperText(
            'These customer details help providers reach the service location correctly.',
          ),
        ],
      );
    }

    if (selectedRole == 'PROVIDER') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Provider Details'),
          TextField(
            controller: fullNameController,
            decoration: inputStyle('Business or Full Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: specialtyController,
            decoration: inputStyle('Service Category'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: serviceController,
            decoration: inputStyle('Service Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: experienceController,
            decoration: inputStyle('Experience (e.g. 5 years)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: addressController,
            decoration: inputStyle('Business Address'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cityController,
            decoration: inputStyle('Service City'),
          ),
          _helperText(
            'Provider requests are reviewed by admin before approval. Keep these details professional and accurate.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Doctor Details'),
        TextField(
          controller: fullNameController,
          decoration: inputStyle('Doctor Full Name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: specialtyController,
          decoration: inputStyle('Specialization'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: hospitalController,
          decoration: inputStyle('Hospital / Clinic Name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: experienceController,
          decoration: inputStyle('Experience (e.g. 8 years)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: licenseController,
          decoration: inputStyle('Registration / License Number'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: cityController,
          decoration: inputStyle('Consultation City'),
        ),
        _helperText(
          'Doctor registrations are reviewed manually. Use your professional medical details for approval.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Account Details'),
                    TextField(
                      controller: usernameController,
                      decoration: inputStyle("Username"),
                    ),
                    _helperText(
                      '4-20 characters. Letters, numbers, and underscores only.',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: inputStyle("Email"),
                    ),
                    _helperText('Use a valid and unique email address.'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: inputStyle("Phone"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: inputStyle("Register As"),
                      items: roleLabels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _roleSpecificFields(),
                    const SizedBox(height: 16),
                    _sectionTitle('Security'),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: inputStyle("Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    _helperText(
                      'Minimum 8 characters with uppercase, lowercase, number, and special character.',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: inputStyle("Confirm Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedRole == 'USER'
                          ? 'Customer accounts can start booking immediately.'
                          : 'Provider and doctor registrations go to admin for approval before login is allowed.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Register"),
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

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      labelText: hint,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F3F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
