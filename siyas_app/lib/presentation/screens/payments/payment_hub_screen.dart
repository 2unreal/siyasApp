import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class PaymentHubScreen extends ConsumerStatefulWidget {
  const PaymentHubScreen({super.key});

  @override
  ConsumerState<PaymentHubScreen> createState() => _PaymentHubScreenState();
}

class _PaymentHubScreenState extends ConsumerState<PaymentHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRefundDialog(BuildContext context, {String? defaultEntityId, String? defaultEntityType}) {
    final entityIdController = TextEditingController(text: defaultEntityId ?? '');
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String method = 'cash';
    String entityType = defaultEntityType ?? 'order';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Issue Refund (Owner Only)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entity Type', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  DropdownButton<String>(
                    value: entityType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'order', child: Text('Order / Tailoring')),
                      DropdownMenuItem(value: 'class', child: Text('Class / Student')),
                    ],
                    onChanged: (val) => setDialogState(() => entityType = val ?? 'order'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: entityIdController,
                    decoration: const InputDecoration(
                      labelText: 'Order / Entity ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Refund Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Refund Method', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI / Online')),
                    ],
                    onChanged: (val) => setDialogState(() => method = val ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Refund',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryWine, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final entityId = entityIdController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());
                        final reason = reasonController.text.trim();

                        if (entityId.isEmpty || amount == null || amount <= 0 || reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields with a valid amount and reason.')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          final res = await ref.read(paymentControllerProvider.notifier).issueRefund(
                                entityType: entityType,
                                entityId: entityId,
                                amount: amount,
                                method: method,
                                reason: reason,
                              );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Refund of ₹${amount.toStringAsFixed(2)} issued. New Balance: ₹${res.newBalance.toStringAsFixed(2)}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Refund failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Refund'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (!auth.isOwner) {
      return _buildManagerPaymentView(context);
    }

    return _buildOwnerLedgerView(context);
  }

  /// Manager-facing Payment View: High-privacy, direct payment recording only
  Widget _buildManagerPaymentView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Collection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 72, color: AppColors.primaryWine),
              const SizedBox(height: 16),
              const Text(
                'Manager Payment Terminal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record client payments via cash or UPI directly to orders.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                color: AppColors.ivorySurface,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.goldDark),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Business privacy active: Historical ledgers, balances, and total collections are restricted to Business Owner review.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryWine,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Select Order to Collect Payment', style: TextStyle(fontSize: 16)),
                  onPressed: () => context.go('/orders'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Owner-facing View: Full Financial Ledgers, Credits, Refunds
  Widget _buildOwnerLedgerView(BuildContext context) {
    final paymentsAsync = ref.watch(ownerPaymentsProvider);
    final creditsAsync = ref.watch(ownerCustomerCreditsProvider);
    final refundsAsync = ref.watch(ownerRefundsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financials & Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_return_outlined),
            tooltip: 'Issue Refund',
            onPressed: () => _showRefundDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldDark,
          labelColor: AppColors.primaryWine,
          tabs: const [
            Tab(text: 'Payments'),
            Tab(text: 'Customer Credits'),
            Tab(text: 'Refunds'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Payments List
          paymentsAsync.when(
            data: (payments) {
              final totalCash = payments.where((p) => p.method == 'cash').fold(0.0, (acc, p) => acc + p.amount);
              final totalUpi = payments.where((p) => p.method == 'upi').fold(0.0, (acc, p) => acc + p.amount);
              final totalSum = totalCash + totalUpi;

              return Column(
                children: [
                  _buildSummaryHeader(totalSum: totalSum, cash: totalCash, upi: totalUpi),
                  Expanded(
                    child: payments.isEmpty
                        ? const Center(child: Text('No payments recorded yet.'))
                        : ListView.separated(
                            itemCount: payments.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = payments[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.method == 'cash'
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  child: Icon(
                                    p.method == 'cash' ? Icons.payments : Icons.qr_code_2,
                                    color: p.method == 'cash' ? Colors.green.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                                title: Text('₹${p.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text(
                                  '${p.entityType.toUpperCase()}: ${p.entityId} • ${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}${p.notes != null ? ' • ${p.notes}' : ''}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.reply, size: 20),
                                  tooltip: 'Refund this order',
                                  onPressed: () => _showRefundDialog(
                                    context,
                                    defaultEntityId: p.entityId,
                                    defaultEntityType: p.entityType,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading payments: $e')),
          ),

          // Tab 2: Customer Credits List
          creditsAsync.when(
            data: (credits) {
              final totalCredits = credits.fold(0.0, (acc, c) => acc + c.amount);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.ivorySurface,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Overpayment Credits:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${totalCredits.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.goldDark)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: credits.isEmpty
                        ? const Center(child: Text('No customer credits recorded.'))
                        : ListView.separated(
                            itemCount: credits.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final c = credits[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFFF8E1),
                                  child: Icon(Icons.account_balance_wallet, color: AppColors.goldDark),
                                ),
                                title: Text('Credit: ₹${c.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Customer: ${c.customerId} • Reason: ${c.reason}'),
                                trailing: Text(
                                  '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading credits: $e')),
          ),

          // Tab 3: Refunds List
          refundsAsync.when(
            data: (refunds) {
              final totalRefunds = refunds.fold(0.0, (acc, r) => acc + r.amount);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade50,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Refunds Issued:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${totalRefunds.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade800)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: refunds.isEmpty
                        ? const Center(child: Text('No refunds issued.'))
                        : ListView.separated(
                            itemCount: refunds.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final r = refunds[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Icon(Icons.money_off, color: Colors.red.shade900),
                                ),
                                title: Text('₹${r.amount.toStringAsFixed(2)} via ${r.method.toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${r.entityType.toUpperCase()}: ${r.entityId} • ${r.reason}'),
                                trailing: Text(
                                  '${r.refundDate.day}/${r.refundDate.month}/${r.refundDate.year}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading refunds: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader({required double totalSum, required double cash, required double upi}) {
    return Container(
      color: AppColors.ivorySurface,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Collections', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('₹${totalSum.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryWine)),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('₹${cash.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPI / QR', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('₹${upi.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
