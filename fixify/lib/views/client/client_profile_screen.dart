import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/client_profile_model.dart';
import '../../providers/client_profile_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _altPhoneController = TextEditingController();

  Gender _selectedGender = Gender.preferNotToSay;
  ContactMethod _selectedContact = ContactMethod.inApp;
  String? _selectedCity;
  bool _formPreloaded = false;

  static const _primaryBlue = Color(0xFF2E5BFF);

  static const _cities = [
    'Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Bizerte',
    'Gabes', 'Ariana', 'Gafsa', 'Monastir', 'Ben Arous',
    'Nabeul', 'Medenine', 'Kasserine', 'Sidi Bouzid', 'Jendouba',
    'Tozeur', 'Mahdia', 'Siliana', 'Kebili', 'Beja',
    'Zaghouan', 'Tataouine', 'Le Kef', 'Manouba',
  ];

  @override
  void initState() {
    super.initState();
    _formPreloaded = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ClientProfileProvider>();
      provider.resetSaveState();
      provider.loadProfile();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

  // Called once when profile data arrives from Firestore
  void _prefillForm(ClientProfile profile) {
    if (_formPreloaded) return;
    _formPreloaded = true;
    _addressController.text = profile.address;
    _altPhoneController.text = profile.alternativePhone ?? '';
    setState(() {
      _selectedCity = _cities.contains(profile.city) ? profile.city : null;
      _selectedGender = profile.gender;
      _selectedContact = profile.preferredContact;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ClientProfileProvider>().saveProfile(
          address: _addressController.text.trim(),
          city: _selectedCity ?? '',
          gender: _selectedGender,
          preferredContact: _selectedContact,
          alternativePhone: _altPhoneController.text.trim().isEmpty
              ? null
              : _altPhoneController.text.trim(),
        );
  }

  void _onSaveSuccess(ClientProfileProvider provider) {
    provider.resetSaveState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // Pop back if editing, replace if first time setup
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home_client');
    }
  }

  void _onSaveError(ClientProfileProvider provider) {
    final msg = provider.errorMessage;
    provider.resetSaveState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProfileProvider>(
      builder: (context, provider, _) {

        // Prefill once data is loaded
        if (provider.profile != null && !_formPreloaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _prefillForm(provider.profile!);
          });
        }

        // Handle post-save navigation/error after build completes
        if (provider.saveState == ProfileSaveState.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onSaveSuccess(provider);
          });
        } else if (provider.saveState == ProfileSaveState.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onSaveError(provider);
          });
        }

        // Show spinner while loading existing profile
        if (provider.isLoadingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _primaryBlue)),
          );
        }

        final isEditing = provider.profile?.profileComplete == true;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              isEditing ? 'Edit profile' : 'Complete your profile',
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tell us about yourself',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This helps us match you with the right technicians.',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  _sectionLabel('Profile Photo', optional: true),
                  const SizedBox(height: 8),
                  _buildPhotoUpload(),
                  const SizedBox(height: 24),

                  _sectionLabel('Address *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hint: '12 Rue de la Republique',
                    prefixIcon: Icons.home_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('City *'),
                  const SizedBox(height: 8),
                  _buildCityDropdown(),
                  const SizedBox(height: 20),

                  _sectionLabel('Gender *'),
                  const SizedBox(height: 8),
                  _buildGenderSelector(),
                  const SizedBox(height: 20),

                  _sectionLabel('Preferred contact method *'),
                  const SizedBox(height: 8),
                  _buildContactMethodSelector(),
                  const SizedBox(height: 20),

                  _sectionLabel('Alternative phone number', optional: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _altPhoneController,
                    hint: '+216 XX XXX XXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                    ],
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: provider.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update profile' : 'Save profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'You can edit your profile anytime from settings.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          const Text('(optional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: () {}, // TODO: integrate image_picker
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 36, color: _primaryBlue),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload a photo',
              style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text('JPG or PNG, max 5MB',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      hint: const Text('Select your city',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.location_city_outlined, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      ),
      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCity = v),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Please select your city' : null,
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: Gender.values.map((g) {
          return RadioListTile<Gender>(
            value: g,
            groupValue: _selectedGender,
            title: Text(_genderLabel(g),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
            activeColor: _primaryBlue,
            dense: true,
            onChanged: (v) => setState(() => _selectedGender = v!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactMethodSelector() {
    final methods = {
      ContactMethod.sms: (Icons.sms_outlined, 'SMS'),
      ContactMethod.email: (Icons.email_outlined, 'Email'),
      ContactMethod.call: (Icons.phone_outlined, 'Call'),
      ContactMethod.inApp: (Icons.notifications_outlined, 'In-app'),
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.entries.map((entry) {
        final isSelected = _selectedContact == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedContact = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryBlue : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.value.$1,
                    size: 18, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  entry.value.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _genderLabel(Gender g) {
    switch (g) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.preferNotToSay: return 'Prefer not to say';
    }
  }
}