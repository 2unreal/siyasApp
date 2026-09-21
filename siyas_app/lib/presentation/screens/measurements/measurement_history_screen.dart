import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/measurement_provider.dart';

class MeasurementHistoryScreen extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const MeasurementHistoryScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(customerMeasurementsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Measurement History', style: TextStyle(fontSize: 18)),
            Text(customerName, style: const TextStyle(fontSize: 13, color: AppColors.goldLight)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.straighten),
        label: const Text('Take Measurements'),
        onPressed: () => context.push(
          '/customers/$customerId/measurements/new',
          extra: customerName,
        ),
      ),
      body: historyAsync.when(
        data: (sets) {
          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.straighten_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No measurements recorded yet.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Record First Set'),
                    onPressed: () => context.push(
                      '/customers/$customerId/measurements/new',
                      extra: customerName,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final mSet = sets[index];
              final isLatest = index == 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isLatest ? AppColors.primaryWine : AppColors.ivorySurface,
                    foregroundColor: isLatest ? Colors.white : AppColors.primaryWine,
                    child: const Icon(Icons.straighten, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        mSet.garmentType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Text(
                            'LATEST',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'Recorded on ${_formatDate(mSet.createdAt)} (${mSet.unit.toUpperCase()})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: mSet.values.entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.ivorySurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Text(
                                  '${_formatLabel(e.key)}: ${e.value} ${mSet.unit == 'inches' ? 'in' : 'cm'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              );
                            }).toList(),
                          ),
                          if (mSet.notes != null && mSet.notes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Notes: ${mSet.notes}',
                              style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Use as Baseline for New Set'),
                            onPressed: () {
                              context.push(
                                '/customers/$customerId/measurements/new',
                                extra: {
                                  'customerName': customerName,
                                  'initialSet': mSet,
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatLabel(String raw) {
    return raw.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
