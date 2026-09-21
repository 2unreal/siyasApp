import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/document_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';

class DocumentHistoryScreen extends ConsumerWidget {
  const DocumentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documents')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: AppColors.primaryWine),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Document generation and history are restricted to Business Owner authorization.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final docsAsync = ref.watch(ownerDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Document History & Invoices')),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No documents generated yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final isInvoice = doc.documentType == DocumentType.invoice;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isInvoice
                      ? AppColors.primaryWine.withValues(alpha: 0.15)
                      : AppColors.goldDark.withValues(alpha: 0.15),
                  child: Icon(
                    isInvoice ? Icons.receipt_long : Icons.payments,
                    color: isInvoice ? AppColors.primaryWine : AppColors.goldDark,
                  ),
                ),
                title: Row(
                  children: [
                    Text(doc.documentNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (doc.isPendingSync) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PENDING SYNC', style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${doc.documentType.displayName} • ${doc.customerName ?? doc.entityId} • ${doc.generatedAt.day}/${doc.generatedAt.month}/${doc.generatedAt.year}',
                ),
                trailing: Text(
                  '₹${doc.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryWine),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading documents: $e')),
      ),
    );
  }
}
