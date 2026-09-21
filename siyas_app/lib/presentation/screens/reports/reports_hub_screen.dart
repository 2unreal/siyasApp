import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  Future<void> _exportCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final row in rows) {
      final formattedRow = row.map((cell) {
        final str = cell?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      buffer.writeln(formattedRow);
    }

    final bytes = utf8.encode(buffer.toString());
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$fileName.csv',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Strict Owner Only RBAC
    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports & Analytics')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 72, color: AppColors.primaryWine),
                SizedBox(height: 16),
                Text('Reports Restricted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Sales reports, financial analysis, and dataset exports are restricted strictly to Business Owner access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final paymentsAsync = ref.watch(ownerPaymentsProvider);
    final ordersAsync = ref.watch(filteredOrdersProvider);
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Dataset Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Standard Business Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _reportCard(
            title: 'Daily & Monthly Sales / Collections',
            subtitle: 'Aggregate cash & UPI revenue breakdown across all billing periods',
            icon: Icons.payments,
            onExportCsv: () {
              final payments = paymentsAsync.asData?.value ?? [];
              _exportCsv(
                fileName: 'collections_report_${DateTime.now().millisecondsSinceEpoch}',
                headers: ['Payment ID', 'Entity Type', 'Entity ID', 'Customer ID', 'Amount (INR)', 'Method', 'Date', 'Notes'],
                rows: payments.map((p) => [
                  p.id,
                  p.entityType,
                  p.entityId,
                  p.customerId ?? '',
                  p.amount,
                  p.method,
                  p.paymentDate.toIso8601String(),
                  p.notes ?? '',
                ]).toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          _reportCard(
            title: 'Outstanding Orders & Balances',
            subtitle: 'List of all active tailoring orders with pending customer collections',
            icon: Icons.pending_actions,
            onExportCsv: () {
              final orders = ordersAsync.asData?.value ?? [];
              _exportCsv(
                fileName: 'outstanding_orders_${DateTime.now().millisecondsSinceEpoch}',
                headers: ['Order Number', 'Customer ID', 'Customer Name', 'Total Amount', 'Status', 'Delivery Date', 'Is Urgent'],
                rows: orders.map((o) => [
                  o.orderNumber,
                  o.customerId,
                  o.customerName,
                  o.totalAmount,
                  o.status.name,
                  o.deliveryDate.toIso8601String(),
                  o.isUrgent,
                ]).toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          _reportCard(
            title: 'Master Customer Directory',
            subtitle: 'Complete list of registered clients with contact info and lifetime metrics',
            icon: Icons.people_alt,
            onExportCsv: () {
              final customers = customersAsync.asData?.value ?? [];
              _exportCsv(
                fileName: 'customers_export_${DateTime.now().millisecondsSinceEpoch}',
                headers: ['Customer ID', 'Name', 'Mobile', 'Address', 'Status', 'Created At'],
                rows: customers.map((c) => [
                  c.customerId,
                  c.name,
                  c.mobile ?? '',
                  c.address ?? '',
                  c.status,
                  c.createdAt.toIso8601String(),
                ]).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onExportCsv,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryWine.withValues(alpha: 0.12),
              child: Icon(icon, color: AppColors.primaryWine),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('CSV'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryWine),
              onPressed: onExportCsv,
            ),
          ],
        ),
      ),
    );
  }
}
