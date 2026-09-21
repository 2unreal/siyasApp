import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? initialCustomer;

  const CustomerFormScreen({super.key, this.initialCustomer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _addressController;
  late final TextEditingController _generalNoteController;

  bool _whatsappSameAsMobile = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _mobileController = TextEditingController(text: c?.mobile ?? '');
    _whatsappController = TextEditingController(text: c?.whatsappMobile ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _generalNoteController = TextEditingController(text: c?.generalNote ?? '');
    _whatsappSameAsMobile = c?.whatsappSameAsMobile ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();

    // Duplicate mobile check for new customer creations
    if (widget.initialCustomer == null && mobile.isNotEmpty) {
      final duplicates = await ref.read(customerControllerProvider.notifier).checkDuplicateMobile(mobile);
      if (duplicates.isNotEmpty && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning),
                SizedBox(width: 8),
                Text('Existing Customer Found'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A customer already exists with mobile number $mobile:'),
                const SizedBox(height: 8),
                Text(
                  '${duplicates.first.name} (${duplicates.first.customerId})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryWine),
                ),
                const SizedBox(height: 12),
                const Text('Mobile numbers do not have to be unique. Do you still wish to create this duplicate record?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryWine),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create Duplicate Anyway'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(customerControllerProvider.notifier).saveCustomer(
            existingId: widget.initialCustomer?.id,
            existingCustomerId: widget.initialCustomer?.customerId,
            name: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            whatsappMobile: _whatsappController.text.trim(),
            whatsappSameAsMobile: _whatsappSameAsMobile,
            address: _addressController.text.trim(),
            generalNote: _generalNoteController.text.trim(),
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save customer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCustomer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'New Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mandatory Name Field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. Deepika Sundaram',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Customer name is mandatory' : null,
              ),
              const SizedBox(height: 16),

              // Optional Mobile Number
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),

              // WhatsApp same as mobile switch
              SwitchListTile(
                title: const Text('WhatsApp number same as mobile'),
                value: _whatsappSameAsMobile,
                activeTrackColor: AppColors.primaryWine,
                onChanged: (val) {
                  setState(() => _whatsappSameAsMobile = val);
                },
              ),

              if (!_whatsappSameAsMobile) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.chat, color: Colors.green),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Door No, Street, Area...',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // General Note
              TextFormField(
                controller: _generalNoteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'General Note',
                  hintText: 'e.g. Prefers padded blouse, likes boat neck...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 28),

              // Quick Save Button (Touch-friendly 48px height)
              ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
