import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import '../documents/document_preview_screen.dart';
import '../payments/payment_entry_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  final Order? initialOrder;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(orderRepositoryProvider);

    return StreamBuilder<Order?>(
      stream: repo.streamOrder(orderId),
      initialData: initialOrder,
      builder: (context, snapshot) {
        final order = snapshot.data;

        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(order.orderNumber),
            actions: [
              PopupMenuButton<OrderStatus>(
                tooltip: 'Update Status',
                onSelected: (newStatus) async {
                  await ref.read(orderControllerProvider.notifier).updateStatus(order.id, newStatus);
                },
                itemBuilder: (ctx) => OrderStatus.values
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text(s.name.toUpperCase()),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Due Date Banner
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              order.status.name.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Due Delivery', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Line Items Breakdown
                const Text('Line Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = order.items[idx];
                      return ListTile(
                        title: Text(item.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.quantity} x ₹${item.unitRate.toStringAsFixed(0)} ${item.description.isNotEmpty ? '• ${item.description}' : ''}'),
                        trailing: Text(
                          '₹${item.lineTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Operational Financial Summary (Subtotal, Discount, Total)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('₹${order.subtotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        if (order.discount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount:'),
                              Text('-₹${order.discount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryWine),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // OWNER-ONLY FINANCIAL STATUS & PAYMENT HISTORY
                if (ref.watch(authProvider).isOwner) ...[
                  const Text('Payment & Balance Status (Owner Only)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryWine)),
                  const SizedBox(height: 8),
                  ref.watch(orderFinancialSummaryProvider(order.id)).when(
                        data: (financials) {
                          if (financials == null) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Financial summary pending synchronization.'),
                              ),
                            );
                          }
                          return Card(
                            color: AppColors.ivorySurface,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Paid:'),
                                      Text(
                                        '₹${financials.totalPaid.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Current Balance:'),
                                      Text(
                                        '₹${financials.balanceAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: financials.balanceAmount > 0 ? AppColors.primaryWine : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (financials.creditAmount > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Customer Credit Available:'),
                                        Text(
                                          '₹${financials.creditAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDark),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                        error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Protected summary error: $e'))),
                      ),
                  const SizedBox(height: 16),
                ],

                // General Note
                if (order.generalNote != null && order.generalNote!.isNotEmpty) ...[
                  const Text('Order Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.ivorySurface,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.goldDark),
                          const SizedBox(width: 10),
                          Expanded(child: Text(order.generalNote!)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action: Record Payment
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryWine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => PaymentEntryScreen(
                            entityType: 'order',
                            entityId: order.id,
                            customerId: order.customerId,
                            orderNumber: order.orderNumber,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Action: Generate Invoice (Owner Only)
                if (ref.watch(authProvider).isOwner) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryWine,
                        side: const BorderSide(color: AppColors.primaryWine, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate Invoice (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final summary = ref.read(orderFinancialSummaryProvider(order.id)).value;
                        final totalPaid = summary?.totalPaid ?? 0.0;
                        final balance = summary?.balanceAmount ?? order.totalAmount;

                        try {
                          final result = await ref.read(documentControllerProvider.notifier).generateOrderInvoice(
                                order: order,
                                totalPaid: totalPaid,
                                balanceAmount: balance,
                              );

                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => DocumentPreviewScreen(
                                  title: 'Invoice — ${order.orderNumber}',
                                  documentNumber: result.record.documentNumber,
                                  pdfBytes: result.pdfBytes,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to generate invoice: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

}

