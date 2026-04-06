import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers
  final _headlineController = TextEditingController();
  final _rateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _radiusController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedTrade;
  int _bioLength = 0;

  final List<String> _trades = [
    'Plumber',
    'Electrician',
    'AC Repair',
    'Painter',
    'Carpenter',
    'Cleaning',
    'Mason',
    'Welder',
    'Appliance Repair',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() => _bioLength = _bioController.text.length);
    });
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _rateController.dispose();
    _experienceController.dispose();
    _radiusController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _isLoadingData = false); return; }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('technician_profiles')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _headlineController.text = data['headline'] ?? '';
        _rateController.text = data['hourlyRate']?.toString() ?? '';
        _experienceController.text = data['yearsOfExperience']?.toString() ?? '';
        _radiusController.text = data['serviceRadius']?.toString() ?? '';
        _bioController.text = data['bio'] ?? '';
        setState(() {
          _selectedTrade = data['trade'];
          _bioLength = _bioController.text.length;
        });
      }
    } catch (_) {}
    setState(() => _isLoadingData = false);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('technician_profiles')
          .doc(uid)
          .set({
        'headline': _headlineController.text.trim(),
        'trade': _selectedTrade,
        'hourlyRate': double.tryParse(_rateController.text.trim()) ?? 0,
        'yearsOfExperience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'serviceRadius': int.tryParse(_radiusController.text.trim()) ?? 0,
        'bio': _bioController.text.trim(),
        'profileComplete': true,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Also mark profile complete on user doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profileComplete': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved! You can now receive jobs.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home_pro');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
      );
    }

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
        title: const Text(
          'Technician Profile',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Set up your Technician profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete your profile to start receiving job requests.\nAll fields marked with * are required.',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Professional Headline
              _sectionLabel('Professional Headline *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _headlineController,
                hint: 'e.g., "Licensed plumber – 10 years"',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Trade
              _sectionLabel('Main Trade / Category *'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),

              // Hourly Rate
              _sectionLabel('Hourly Rate (DT) *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _rateController,
                hint: '45',
                suffix: '/hr',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Years of Experience
              _sectionLabel('Years of Experience *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _experienceController,
                hint: '10',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Service Radius
              _sectionLabel('Service Radius (km) *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _radiusController,
                hint: '9',
                prefixIcon: Icons.location_on_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Short Bio
              _sectionLabel('Short Bio *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Tell clients about yourself, your skills and experience...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '$_bioLength / 300 characters',
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
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Profile Photo
              _sectionLabel('Profile Photo (Optional)'),
              const SizedBox(height: 8),
              _buildUploadBox(
                icon: Icons.upload_outlined,
                label: 'Upload a photo',
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // License / Insurance
              _sectionLabel('License / Insurance *'),
              const SizedBox(height: 4),
              const Text(
                'May be required later before accepting jobs',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildUploadBox(
                icon: Icons.upload_file_outlined,
                label: 'Upload document',
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Start receiving jobs',
                          style: TextStyle(
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
                  'Complete all required fields to continue.\nYou can edit your profile anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
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
        suffixText: suffix,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTrade,
      hint: const Text('Choose option...', style: TextStyle(color: Colors.grey, fontSize: 14)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
      ),
      items: _trades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedTrade = v),
      validator: (v) => v == null ? 'Please select your trade' : null,
    );
  }

  Widget _buildUploadBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}