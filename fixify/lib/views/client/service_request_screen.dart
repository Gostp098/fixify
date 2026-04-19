
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_request_provider.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({Key? key}) : super(key: key);

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();

  ServiceCategory? _selectedCategory;
  TimeSlot? _selectedTimeSlot;
  DateTime? _selectedDate;
  UrgencyLevel _urgency = UrgencyLevel.normal;
  bool _addressPrefilled = false;

  static const _primaryBlue = Color(0xFF2E5BFF);
  static const _urgentOrange = Color(0xFFF97316);

  // ── Category options ──────────────────────────────────────
  static const _categories = {
    ServiceCategory.plumbing: (Icons.plumbing, 'Plumbing'),
    ServiceCategory.electrical: (Icons.electrical_services, 'Electrical'),
    ServiceCategory.cleaning: (Icons.cleaning_services, 'Cleaning'),
    ServiceCategory.acRepair: (Icons.ac_unit, 'AC Repair'),
    ServiceCategory.painting: (Icons.format_paint, 'Painting'),
    ServiceCategory.carpentry: (Icons.carpenter, 'Carpentry'),
    ServiceCategory.welding: (Icons.handyman, 'Welding'),
    ServiceCategory.applianceRepair: (Icons.kitchen, 'Appliance Repair'),
    ServiceCategory.other: (Icons.miscellaneous_services, 'Other'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceRequestProvider>().resetState();
      context.read<ServiceRequestProvider>().loadSavedAddress();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ── Prefill address once loaded ───────────────────────────
  void _prefillAddress(String address) {
    if (_addressPrefilled || address.isEmpty) return;
    _addressPrefilled = true;
    _addressController.text = address;
  }

  // ── Date picker ───────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preferred date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<ServiceRequestProvider>().submitRequest(
          category: _selectedCategory!,
          description: _descriptionController.text,
          preferredDate: _selectedDate!,
          timeSlot: _selectedTimeSlot!,
          address: _addressController.text,
          apartmentInstructions: _instructionsController.text.isEmpty
              ? null
              : _instructionsController.text,
          urgency: _urgency,
        );
  }

  // ── Post-submit handlers ──────────────────────────────────
  void _onSuccess(ServiceRequestProvider provider) {
    provider.resetState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submitted! We\'ll find you a technician.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacementNamed(context, '/home_client');
  }

  void _onError(ServiceRequestProvider provider) {
    final msg = provider.errorMessage;
    provider.resetState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestProvider>(
      builder: (context, provider, _) {
        // Prefill address when loaded
        if (provider.savedAddress.isNotEmpty && !_addressPrefilled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _prefillAddress(provider.savedAddress);
          });
        }

        // Handle submit result
        if (provider.submitState == SubmitState.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onSuccess(provider);
          });
        } else if (provider.submitState == SubmitState.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onError(provider);
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'New Service Request',
              style: TextStyle(
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
                  // Header
                  const Text(
                    'What do you need help with?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fill in the details and we\'ll match you with a technician.',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  // 1. Service Category
                  _sectionLabel('Service category *'),
                  const SizedBox(height: 8),
                  _buildCategoryGrid(),
                  if (_selectedCategory == null && _formKey.currentState != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text('Please select a category',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),

                  // 2. Description
                  _sectionLabel('Description of issue *'),
                  const SizedBox(height: 8),
                  _buildDescriptionField(),
                  const SizedBox(height: 20),

                  // 3. Preferred Date
                  _sectionLabel('Preferred date *'),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // 4. Time Slot
                  _sectionLabel('Preferred time slot *'),
                  const SizedBox(height: 8),
                  _buildTimeSlotDropdown(),
                  const SizedBox(height: 20),

                  // 5. Address
                  _sectionLabel('Address *'),
                  const SizedBox(height: 4),
                  const Text(
                    'Pre-filled from your profile — edit if the job is elsewhere.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Enter service address',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // 6. Apartment / Instructions
                  _sectionLabel('Apartment / instructions', optional: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _instructionsController,
                    hint: 'e.g. Building B, 3rd floor, ring bell twice',
                    prefixIcon: Icons.info_outline,
                  ),
                  const SizedBox(height: 20),

                  // 7. Urgency
                  _sectionLabel('Urgency level', optional: true),
                  const SizedBox(height: 8),
                  _buildUrgencySelector(),
                  const SizedBox(height: 20),

                  // 8. Attach Photos
                  _sectionLabel('Attach photos', optional: true),
                  const SizedBox(height: 8),
                  _buildPhotoUpload(),
                  const SizedBox(height: 36),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _urgency == UrgencyLevel.urgent
                            ? _urgentOrange
                            : _primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: provider.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_urgency == UrgencyLevel.urgent) ...[
                                  const Icon(Icons.flash_on,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                ],
                                const Text(
                                  'Submit request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Your request will be sent to available technicians nearby.',
                      textAlign: TextAlign.center,
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

  // ── UI Builders ────────────────────────────────────────────

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
          const Text('(optional)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: _categories.entries.map((entry) {
        final isSelected = _selectedCategory == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryBlue
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryBlue : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _primaryBlue.withOpacity(0.2), blurRadius: 8)]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  entry.value.$1,
                  size: 26,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(height: 6),
                Text(
                  entry.value.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      maxLength: 500,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please describe the issue';
        if (v.trim().length < 10) return 'Please provide more detail (min 10 characters)';
        return null;
      },
      decoration: InputDecoration(
        hintText: 'e.g. My kitchen sink is leaking under the cabinet and water is dripping onto the floor...',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
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
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Select a date'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                fontSize: 14,
                color: _selectedDate == null
                    ? Colors.grey
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotDropdown() {
    return DropdownButtonFormField<TimeSlot>(
      value: _selectedTimeSlot,
      hint: const Text('Select time slot',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.access_time_outlined, color: Colors.grey, size: 20),
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
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
      ),
      items: TimeSlot.values.map((t) {
        final labels = {
          TimeSlot.morning: 'Morning (08:00 – 12:00)',
          TimeSlot.afternoon: 'Afternoon (12:00 – 17:00)',
          TimeSlot.evening: 'Evening (17:00 – 21:00)',
        };
        return DropdownMenuItem(value: t, child: Text(labels[t]!));
      }).toList(),
      onChanged: (v) => setState(() => _selectedTimeSlot = v),
      validator: (v) => v == null ? 'Please select a time slot' : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          RadioListTile<UrgencyLevel>(
            value: UrgencyLevel.normal,
            groupValue: _urgency,
            activeColor: _primaryBlue,
            dense: true,
            title: const Text('Normal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: const Text('Standard response time',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            onChanged: (v) => setState(() => _urgency = v!),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          RadioListTile<UrgencyLevel>(
            value: UrgencyLevel.urgent,
            groupValue: _urgency,
            activeColor: _urgentOrange,
            dense: true,
            title: Row(
              children: [
                const Text('Urgent',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _urgentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Priority',
                      style: TextStyle(
                          fontSize: 11,
                          color: _urgentOrange,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            subtitle: const Text('Faster assignment, may affect pricing',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            onChanged: (v) => setState(() => _urgency = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: () {
        // TODO: integrate image_picker for multiple images
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'Add photos of the issue',
              style: TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG or PNG, up to 5 photos',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
