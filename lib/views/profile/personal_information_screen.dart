import 'package:flutter/material.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String? completePhoneNumber;
  String? _phoneOnly;
  String _initialCountry = 'EG'; // Égypte par défaut
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().userData!;

    _usernameController = TextEditingController(text: user['username'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');

    final rawPhone = user['numeroTelephone'] ?? '';
    if (rawPhone.startsWith('+20')) {
      completePhoneNumber = rawPhone;
      _phoneOnly = rawPhone.replaceFirst('+20', '').trim();
      _initialCountry = 'EG';
    } else if (rawPhone.startsWith('+216')) {
      completePhoneNumber = rawPhone;
      _phoneOnly = rawPhone.replaceFirst('+216', '').trim();
      _initialCountry = 'TN';
    } else {
      completePhoneNumber = rawPhone;
      _phoneOnly = rawPhone;
    }

    final dob = user['dateOfBirth'];
    if (dob != null && dob.toString().isNotEmpty) {
      selectedDate = DateTime.tryParse(dob);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final formattedDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : 'Date de naissance';

    return Scaffold(
      backgroundColor: const Color(0xFFFCF4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildForm(formattedDate),
                      ],
                    ),
                  ),
                  _buildSaveButton(vm),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF5F0), Color.fromARGB(255, 215, 146, 117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _usernameController.text.isEmpty ? 'Utilisateur' : _usernameController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildForm(String formattedDate) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Field(
                label: "Nom d'utilisateur",
                controller: _usernameController,
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ce champ est requis' : null,
              ),
              const _DividerInset(),
              _Field(
                label: "Email",
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ce champ est requis' : null,
              ),
              const _DividerInset(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _LeadingIcon(icon: Icons.phone_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IntlPhoneField(
                        initialCountryCode: _initialCountry,
                        initialValue: _phoneOnly,
                        disableLengthCheck: true,
                        dropdownIconPosition: IconPosition.trailing,
                        onChanged: (p) => completePhoneNumber = p.completeNumber,
                        decoration: InputDecoration(
                          hintText: 'Téléphone',
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _DividerInset(),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _LeadingIcon(icon: Icons.calendar_month_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 15.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

  Widget _buildSaveButton(AuthViewModel vm) => Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: vm.isLoading ? null : _onSave,
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: const Text(
              'Enregistrer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE6B33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      );

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une date de naissance')),
      );
      return;
    }
    if (completePhoneNumber == null || completePhoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un numéro de téléphone valide')),
      );
      return;
    }
   final data = {
  'firstName': _usernameController.text.trim().split(' ').first,
  'lastName': _usernameController.text.trim().split(' ').skip(1).join(' '),
  'email': _emailController.text.trim(),
  'mobile': completePhoneNumber!,
  'dateOfBirth': selectedDate!.toIso8601String(),
};

    context.read<AuthViewModel>().updateUserProfile(data, context);
  }
}

/* ------------------------------- Widgets UI ------------------------------ */

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFFEE6B33)),
    );
  }
}

class _DividerInset extends StatelessWidget {
  const _DividerInset();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 50);
  }
}
