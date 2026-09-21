import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/payment_provider.dart';
import '../documents/document_preview_screen.dart';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  final String entityType;
  final String entityId;
  final String? customerId;
  final String? orderNumber;
  final double? suggestedAmount;

  const PaymentEntryScreen({
    super.key,
    this.entityType = 'order',
    required this.entityId,
    this.customerId,
    this.orderNumber,
    this.suggestedAmount,
  });

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'cash'; // 'cash' | 'upi'
  bool _isSubmitting = false;
  PaymentResult? _recordedResult;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedAmount != null && widget.suggestedAmount! > 0) {
      _amountController.text = widget.suggestedAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref.read(paymentControllerProvider.notifier).recordPayment(
            entityType: widget.entityType,
            entityId: widget.entityId,
            amount: amount,
            method: _selectedMethod,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            customerId: widget.customerId,
          );

      setState(() {
        _isSubmitting = false;
        _recordedResult = result;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderNumber != null ? 'Payment — ${widget.orderNumber}' : 'Record Payment'),
      ),
      body: _recordedResult != null ? _buildSuccessView() : _buildEntryForm(),
    );
  }

  Widget _buildEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Entity Banner
            Card(
              color: AppColors.ivorySurface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primaryWine, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entityType == 'order' ? 'Tailoring / Order Payment' : 'Class / Student Fee',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.orderNumber ?? 'Entity ID: ${widget.entityId}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input Field
            const Text(
              'Payment Amount (₹)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Amount must be greater than zero';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Quick Amount Buttons
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000].map((quick) {
                return ActionChip(
                  label: Text('+₹$quick'),
                  onPressed: () {
                    final current = double.tryParse(_amountController.text) ?? 0.0;
                    _amountController.text = (current + quick).toStringAsFixed(0);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'cash' ? AppColors.primaryWine.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedMethod == 'cash' ? AppColors.primaryWine : Colors.grey.shade300,
                          width: _selectedMethod == 'cash' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: _selectedMethod == 'cash' ? AppColors.primaryWine : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cash',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'cash' ? AppColors.primaryWine : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = 'upi'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedMethod == 'upi' ? AppColors.primaryWine.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedMethod == 'upi' ? AppColors.primaryWine : Colors.grey.shade300,
                          width: _selectedMethod == 'upi' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_outlined,
                            color: _selectedMethod == 'upi' ? AppColors.primaryWine : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'UPI / QR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedMethod == 'upi' ? AppColors.primaryWine : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Optional Notes
            const Text(
              'Remarks / Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g. Advance payment, GPay ref #12345',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryWine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSubmitting ? null : _submitPayment,
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final res = _recordedResult!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Payment Recorded Successfully',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Received:', style: TextStyle(fontSize: 15)),
                        Text('₹${res.amountRecorded.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method:', style: TextStyle(fontSize: 15)),
                        Text(_selectedMethod.toUpperCase(),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Balance:', style: TextStyle(fontSize: 15)),
                        Text(
                          '₹${res.newBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: res.newBalance > 0 ? AppColors.primaryWine : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (res.creditAmount > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer Credit Created:', style: TextStyle(fontSize: 15)),
                          Text(
                            '₹${res.creditAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Atomic transaction recorded. Historical payment logs remain protected under Owner access rules.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Owner Only: Generate Payment Receipt
            if (ref.watch(authProvider).isOwner) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryWine,
                    side: const BorderSide(color: AppColors.primaryWine, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate Receipt (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    try {
                      final payment = Payment(
                        id: res.paymentId,
                        entityType: widget.entityType,
                        entityId: widget.entityId,
                        customerId: widget.customerId,
                        amount: res.amountRecorded,
                        method: _selectedMethod,
                        paymentDate: DateTime.now(),
                        recordedBy: ref.read(authProvider).uid ?? 'owner',
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      final receiptResult = await ref.read(documentControllerProvider.notifier).generatePaymentReceipt(
                            payment: payment,
                            orderTotal: res.amountRecorded + res.newBalance,
                            resultingBalance: res.newBalance,
                            creditAmount: res.creditAmount,
                          );

                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => DocumentPreviewScreen(
                              title: 'Payment Receipt',
                              documentNumber: receiptResult.record.documentNumber,
                              pdfBytes: receiptResult.pdfBytes,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to generate receipt: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryWine,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/orders');
                  }
                },
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
