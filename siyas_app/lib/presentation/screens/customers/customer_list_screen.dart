import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final statusFilter = ref.watch(customerStatusFilterProvider);
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(filteredCustomersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('New Customer'),
        onPressed: () => context.push('/customers/new'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name, Mobile, ID, WhatsApp...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryWine),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(customerSearchQueryProvider.notifier).state = '';
                  },
                ),
              ),
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Segment Filter Tabs (Active vs Archived - Owner Only)
          if (auth.isOwner) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'active',
                          label: Text('Active Customers'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                        ButtonSegment(
                          value: 'archived',
                          label: Text('Archived'),
                          icon: Icon(Icons.archive_outlined),
                        ),
                      ],
                      selected: {statusFilter},
                      onSelectionChanged: (set) {
                        ref.read(customerStatusFilterProvider.notifier).state = set.first;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Customer List View
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          statusFilter == 'active' ? Icons.people_outline : Icons.archive_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusFilter == 'active' ? 'No active customers found' : 'No archived customers',
                          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return CustomerCard(customer: customer);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading customers: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryWineLight,
          foregroundColor: Colors.white,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.ivorySurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                customer.customerId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryWine,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.mobile != null && customer.mobile!.isNotEmpty)
                Text('Mobile: ${customer.mobile}'),
              if (customer.generalNote != null && customer.generalNote!.isNotEmpty)
                Text(
                  customer.generalNote!,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          context.push('/customers/${customer.id}', extra: customer);
        },
      ),
    );
  }
}
