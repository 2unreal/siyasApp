import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  final Customer? initialCustomer;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Dated Note'),
        content: TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter observation, preference, or update...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_noteController.text.trim().isNotEmpty) {
                await ref.read(customerControllerProvider.notifier).addNote(
                      customerId: widget.customerId,
                      note: _noteController.text.trim(),
                    );
                _noteController.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final repo = ref.watch(customerRepositoryProvider);
    final notesAsync = ref.watch(customerNotesProvider(widget.customerId));

    return StreamBuilder<Customer?>(
      stream: repo.streamCustomer(widget.customerId),
      initialData: widget.initialCustomer,
      builder: (context, snapshot) {
        final customer = snapshot.data;

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Customer',
                onPressed: () => context.push('/customers/${customer.id}/edit', extra: customer),
              ),
              // Owner-only Archive / Restore button
              if (auth.isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'archive') {
                      await ref.read(customerControllerProvider.notifier).archiveCustomer(customer.id);
                      if (context.mounted) context.pop();
                    } else if (value == 'restore') {
                      await ref.read(customerControllerProvider.notifier).restoreCustomer(customer.id);
                      if (context.mounted) context.pop();
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!customer.isArchived)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive, color: AppColors.statusWarning),
                            SizedBox(width: 8),
                            Text('Archive Customer'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.unarchive, color: AppColors.statusSuccess),
                            SizedBox(width: 8),
                            Text('Restore Customer'),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryWine,
                              foregroundColor: Colors.white,
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    customer.customerId,
                                    style: const TextStyle(color: AppColors.primaryWine, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: customer.isArchived ? Colors.grey.shade200 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.status.toUpperCase(),
                                style: TextStyle(
                                  color: customer.isArchived ? Colors.grey.shade700 : AppColors.statusSuccess,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (customer.mobile != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 18, color: AppColors.primaryWine),
                              const SizedBox(width: 8),
                              Text(customer.mobile!, style: const TextStyle(fontSize: 15)),
                              if (customer.whatsappSameAsMobile) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.chat, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (!customer.whatsappSameAsMobile && customer.whatsappMobile != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.chat, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('WhatsApp: ${customer.whatsappMobile!}', style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (customer.address != null && customer.address!.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(customer.address!, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Action: Measurements Hub
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.straighten, color: AppColors.primaryWine),
                    label: const Text('View / Record Measurements'),
                    onPressed: () {
                      context.push(
                        '/customers/${customer.id}/measurements',
                        extra: customer.name,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // General Note
                if (customer.generalNote != null && customer.generalNote!.isNotEmpty) ...[
                  const Text('General Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Card(
                    color: AppColors.ivorySurface,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.goldDark, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(customer.generalNote!, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes History Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notes History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Add Note'),
                      onPressed: () => _showAddNoteDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                notesAsync.when(
                  data: (notes) {
                    if (notes.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No notes history recorded yet.')),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notes.length,
                      itemBuilder: (context, idx) {
                        final note = notes[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.note, color: AppColors.primaryWine),
                            title: Text(note.note),
                            subtitle: Text(
                              '${note.authorName} • ${_formatDate(note.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading notes: $e'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
