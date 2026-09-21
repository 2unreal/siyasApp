import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/alteration_model.dart';
import '../../providers/alteration_provider.dart';
import '../../providers/auth_provider.dart';

class AlterationHubScreen extends ConsumerStatefulWidget {
  const AlterationHubScreen({super.key});

  @override
  ConsumerState<AlterationHubScreen> createState() => _AlterationHubScreenState();
}

class _AlterationHubScreenState extends ConsumerState<AlterationHubScreen> {
  void _showNewAlterationDialog(BuildContext context) {
    final orderCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final chargeCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    DateTime expectedDate = DateTime.now().add(const Duration(days: 2));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Log Alteration Request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: orderCtrl,
                    decoration: const InputDecoration(labelText: 'Original Order Number / ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(labelText: 'Customer ID / Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Garment / Area',
                      hintText: 'e.g. Blouse Waist, Sleeve Length',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alteration Description',
                      hintText: 'e.g. Take in by 1 inch at side seams',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chargeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Additional Charge (₹)',
                            helperText: '0 for free / warranty alteration',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: expectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setDialogState(() => expectedDate = picked);
                            }
                          },
                          child: Text('Due: ${expectedDate.day}/${expectedDate.month}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Internal Notes'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryWine,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final orderId = orderCtrl.text.trim();
                        final customerId = customerCtrl.text.trim();
                        final area = areaCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        final charge = double.tryParse(chargeCtrl.text.trim()) ?? 0.0;

                        if (orderId.isEmpty || customerId.isEmpty || area.isEmpty || desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await ref.read(alterationControllerProvider.notifier).createAlteration(
                                originalOrderId: orderId,
                                customerId: customerId,
                                description: desc,
                                area: area,
                                expectedCompletionDate: expectedDate,
                                additionalCharge: charge,
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                createdBy: ref.read(authProvider).uid ?? 'staff',
                              );

                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alteration logged successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Log Alteration'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alterationsAsync = ref.watch(alterationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alterations')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Alteration'),
        onPressed: () => _showNewAlterationDialog(context),
      ),
      body: alterationsAsync.when(
        data: (alterations) {
          if (alterations.isEmpty) {
            return const Center(child: Text('No alterations registered.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: alterations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final alt = alterations[idx];
              final isDelivered = alt.status == AlterationStatus.delivered;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDelivered
                      ? Colors.grey.shade200
                      : AppColors.primaryWine.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.straighten,
                    color: isDelivered ? Colors.grey : AppColors.primaryWine,
                  ),
                ),
                title: Row(
                  children: [
                    Text(alt.alterationNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alt.isFree ? Colors.green.shade100 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alt.isFree ? 'FREE' : '₹${alt.additionalCharge.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: alt.isFree ? Colors.green.shade900 : Colors.brown.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Order: ${alt.originalOrderId} • Area: ${alt.area}\n${alt.description}\nExpected: ${alt.expectedCompletionDate.day}/${alt.expectedCompletionDate.month}/${alt.expectedCompletionDate.year} • Status: ${alt.status.name.toUpperCase()}',
                ),
                trailing: PopupMenuButton<AlterationStatus>(
                  onSelected: (newStatus) async {
                    await ref.read(alterationControllerProvider.notifier).updateAlterationStatus(
                          alteration: alt,
                          newStatus: newStatus,
                        );
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: AlterationStatus.inProgress,
                      child: Text('Mark In Progress'),
                    ),
                    const PopupMenuItem(
                      value: AlterationStatus.ready,
                      child: Text('Mark Ready'),
                    ),
                    const PopupMenuItem(
                      value: AlterationStatus.delivered,
                      child: Text('Mark Delivered'),
                    ),
                    const PopupMenuItem(
                      value: AlterationStatus.cancelled,
                      child: Text('Cancel Alteration'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading alterations: $e')),
      ),
    );
  }
}
