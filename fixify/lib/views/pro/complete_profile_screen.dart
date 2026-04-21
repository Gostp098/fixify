import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/technician_profile_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headlineController = TextEditingController();
  final _rateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _radiusController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedTrade;
  int _bioLength = 0;
  bool _formPreloaded = false;

  static const _orange = Color(0xFFF97316);

  static const _trades = [
    'Plumber', 'Electrician', 'AC Repair', 'Painter',
    'Carpenter', 'Cleaning', 'Mason', 'Welder',
    'Appliance Repair', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _bioController.addListener(
        () => setState(() => _bioLength = _bioController.text.length));
    _formPreloaded = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TechnicianProfileProvider>();
      p.resetSaveState();
      p.loadProfile();
    });
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

  void _prefillForm(TechnicianProfileProvider provider) {
    if (_formPreloaded || provider.profile == null) return;
    _formPreloaded = true;
    final p = provider.profile!;
    _headlineController.text = p.headline;
    _rateController.text =
        p.hourlyRate > 0 ? p.hourlyRate.toStringAsFixed(0) : '';
    _experienceController.text =
        p.yearsOfExperience > 0 ? p.yearsOfExperience.toString() : '';
    _radiusController.text =
        p.serviceRadius > 0 ? p.serviceRadius.toString() : '';
    _bioController.text = p.bio;
    setState(() {
      _selectedTrade = _trades.contains(p.trade) ? p.trade : null;
      _bioLength = p.bio.length;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TechnicianProfileProvider>().saveProfile(
          headline: _headlineController.text,
          trade: _selectedTrade!,
          hourlyRate:
              double.tryParse(_rateController.text.trim()) ?? 0,
          yearsOfExperience:
              int.tryParse(_experienceController.text.trim()) ?? 0,
          serviceRadius:
              int.tryParse(_radiusController.text.trim()) ?? 0,
          bio: _bioController.text,
        );
  }

  void _onSuccess(TechnicianProfileProvider provider) {
    provider.resetSaveState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved! You can now receive jobs.'),
        backgroundColor: Colors.green,
      ),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home_pro');
    }
  }

  void _onError(TechnicianProfileProvider provider) {
    final msg = provider.errorMessage;
    provider.resetSaveState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianProfileProvider>(
      builder: (context, provider, _) {
        // Prefill once profile loads
        if (provider.profile != null && !_formPreloaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _prefillForm(provider);
          });
        }

        // Handle save result after build
        if (provider.saveState == ProfileSaveState.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onSuccess(provider);
          });
        } else if (provider.saveState == ProfileSaveState.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onError(provider);
          });
        }

        if (provider.isLoadingProfile) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: _orange)),
          );
        }

        final isEditing =
            provider.profile?.profileComplete == true;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Color(0xFF1A1A2E)),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              isEditing ? 'Edit Profile' : 'Technician Profile',
              style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.bold),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Update your profile'
                        : 'Set up your Technician profile',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Complete your profile to start receiving job requests.\nAll fields marked * are required.',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  // Professional Headline
                  _sectionLabel('Professional Headline *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _headlineController,
                    hint: 'e.g. Licensed plumber – 10 years',
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Trade
                  _sectionLabel('Main Trade / Category *'),
                  const SizedBox(height: 8),
                  _buildTradeDropdown(),
                  const SizedBox(height: 20),
                  // Hourly Rate
                  _sectionLabel('Hourly Rate (DT) *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _rateController,
                    hint: '45',
                    suffix: '/hr',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Years of Experience
                  _sectionLabel('Years of Experience *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _experienceController,
                    hint: '10',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : null,
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  _sectionLabel('Short Bio *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText:
                          'Tell clients about yourself, your skills and experience...',
                      hintStyle: const TextStyle(
                          color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '$_bioLength / 300 characters',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _orange, width: 1.5),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Profile photo (placeholder)
                  _sectionLabel('Profile Photo (optional)'),
                  const SizedBox(height: 8),
                  _buildUploadBox(
                    icon: Icons.upload_outlined,
                    label: 'Upload a photo',
                    onTap: () {}, // TODO: image_picker
                  ),
                  const SizedBox(height: 20),

                  // License
                  _sectionLabel('License / Insurance (optional)'),
                  const SizedBox(height: 4),
                  const Text(
                    'May be required before accepting certain jobs.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildUploadBox(
                    icon: Icons.upload_file_outlined,
                    label: 'Upload document',
                    onTap: () {}, // TODO: image_picker
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          provider.isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                              isEditing
                                  ? 'Update profile'
                                  : 'Start receiving jobs',
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
                      'You can edit your profile anytime.',
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
        hintStyle:
            const TextStyle(color: Colors.grey, fontSize: 14),
        suffixText: suffix,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildTradeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTrade,
      hint: const Text('Choose your trade...',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: _orange, width: 1.5),
        ),
      ),
      items: _trades
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _selectedTrade = v),
      validator: (v) =>
          v == null ? 'Please select your trade' : null,
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
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}