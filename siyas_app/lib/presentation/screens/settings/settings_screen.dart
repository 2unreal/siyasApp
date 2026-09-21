import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/settings_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _orderPrefixCtrl;
  late TextEditingController _invoicePrefixCtrl;
  late TextEditingController _receiptPrefixCtrl;
  late TextEditingController _rentalPrefixCtrl;
  late TextEditingController _altPrefixCtrl;
  late TextEditingController _classPrefixCtrl;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _initControllers(settings);
  }

  void _initControllers(StudioSettings settings) {
    _nameCtrl = TextEditingController(text: settings.studioName);
    _phoneCtrl = TextEditingController(text: settings.phone);
    _whatsappCtrl = TextEditingController(text: settings.whatsapp);
    _addressCtrl = TextEditingController(text: settings.address);
    _taxCtrl = TextEditingController(text: settings.taxGst);
    _orderPrefixCtrl = TextEditingController(text: settings.orderPrefix);
    _invoicePrefixCtrl = TextEditingController(text: settings.invoicePrefix);
    _receiptPrefixCtrl = TextEditingController(text: settings.receiptPrefix);
    _rentalPrefixCtrl = TextEditingController(text: settings.rentalPrefix);
    _altPrefixCtrl = TextEditingController(text: settings.alterationPrefix);
    _classPrefixCtrl = TextEditingController(text: settings.classPrefix);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _taxCtrl.dispose();
    _orderPrefixCtrl.dispose();
    _invoicePrefixCtrl.dispose();
    _receiptPrefixCtrl.dispose();
    _rentalPrefixCtrl.dispose();
    _altPrefixCtrl.dispose();
    _classPrefixCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    final updated = StudioSettings(
      studioName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      taxGst: _taxCtrl.text.trim(),
      orderPrefix: _orderPrefixCtrl.text.trim(),
      invoicePrefix: _invoicePrefixCtrl.text.trim(),
      receiptPrefix: _receiptPrefixCtrl.text.trim(),
      rentalPrefix: _rentalPrefixCtrl.text.trim(),
      alterationPrefix: _altPrefixCtrl.text.trim(),
      classPrefix: _classPrefixCtrl.text.trim(),
      updatedAt: DateTime.now(),
      updatedBy: 'owner',
    );

    ref.read(settingsProvider.notifier).updateSettings(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully.'),
        backgroundColor: AppColors.primaryWine,
      ),
    );
  }

  void _resetDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text('Are you sure you want to restore all studio branding and numbering prefixes to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryWine),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(settingsProvider.notifier).resetToDefaults();
              final s = ref.read(settingsProvider);
              setState(() {
                _initControllers(s);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to business defaults.')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.red.shade50,
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Studio Settings and business configuration are strictly restricted to the Owner role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final env = AppConfig.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to Defaults',
            onPressed: _resetDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Studio Profile & Branding
            _buildSectionHeader(Icons.storefront, 'Studio Profile & Branding'),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Studio Name', prefixIcon: Icon(Icons.business)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(labelText: 'Contact Phone', prefixIcon: Icon(Icons.phone)),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _whatsappCtrl,
                            decoration: const InputDecoration(labelText: 'WhatsApp Number', prefixIcon: Icon(Icons.chat)),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Studio Address', prefixIcon: Icon(Icons.location_on)),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxCtrl,
                      decoration: const InputDecoration(labelText: 'GSTIN / Tax ID (Optional)', prefixIcon: Icon(Icons.receipt_long)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Document & Sequence Prefixes
            _buildSectionHeader(Icons.tag, 'Document Numbering Prefixes'),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _orderPrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Order Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _invoicePrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Invoice Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receiptPrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Receipt Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _rentalPrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Rental Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _altPrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Alteration Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _classPrefixCtrl,
                            decoration: const InputDecoration(labelText: 'Class Prefix'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Communication Templates
            _buildSectionHeader(Icons.mark_chat_unread_outlined, 'Communication Templates'),
            Card(
              elevation: 1,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryWine),
                    title: const Text('Order Confirmation Template'),
                    subtitle: const Text('Namaste {CustomerName}! Your order {OrderNumber} has been received at House of SIYA\'s.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: const Text('Order Ready for Delivery Template'),
                    subtitle: const Text('Namaste {CustomerName}! Your outfit for order {OrderNumber} is ready for trial/pickup.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_outlined, color: AppColors.goldAccent),
                    title: const Text('Payment Receipt Template'),
                    subtitle: const Text('Namaste {CustomerName}! Payment of ₹{Amount} received with thanks.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Role & Security Overview
            _buildSectionHeader(Icons.security, 'Zero-Trust Role & Access Control'),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Current User Role: ${auth.role.name.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Owner: Unrestricted access to financial metrics, historical ledger, reports, settings, classes, and PDF generation.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Manager: Operational duties only (taking orders, recording single payments, managing rentals/alterations). Payment history, revenue, financial summaries, and invoice creation are strictly inaccessible.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 5: System & Environment Diagnostics
            _buildSectionHeader(Icons.info_outline, 'System & Environment Information'),
            Card(
              elevation: 1,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: const Text('Environment Profile'),
                    subtitle: Text('${env.environment.name.toUpperCase()} (${env.isDev ? "Development Isolated" : "Production Live"})'),
                    trailing: Chip(
                      label: Text(env.environment.name.toUpperCase()),
                      backgroundColor: env.isDev ? Colors.orange.shade100 : Colors.green.shade100,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Firebase Project ID'),
                    subtitle: Text(env.projectId),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('Cloud Storage Bucket'),
                    subtitle: Text(env.storageBucket),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.sync, color: Colors.blue),
                    title: Text('Offline Sync & Persistence'),
                    subtitle: Text('Local Firestore Cache enabled with pending writes tracking.'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.app_settings_alt),
                    title: Text('App Build Version'),
                    subtitle: Text('1.0.0+1 (Architecture: Milestone 0 Compliant)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Settings Button
            ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save Studio Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryWine,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryWine),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
          ),
        ],
      ),
    );
  }
}
