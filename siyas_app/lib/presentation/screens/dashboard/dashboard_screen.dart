import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/rental_provider.dart';

enum DashboardDateFilter {
  today,
  tomorrow,
  thisWeek,
  all,
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardDateFilter _selectedFilter = DashboardDateFilter.today;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(filteredOrdersProvider);
    final rentalsAsync = ref.watch(rentalTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Dashboard'),
        actions: [
          PopupMenuButton<DashboardDateFilter>(
            initialValue: _selectedFilter,
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filter Range',
            onSelected: (val) => setState(() => _selectedFilter = val),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: DashboardDateFilter.today, child: Text('Today')),
              PopupMenuItem(value: DashboardDateFilter.tomorrow, child: Text('Tomorrow')),
              PopupMenuItem(value: DashboardDateFilter.thisWeek, child: Text('This Week')),
              PopupMenuItem(value: DashboardDateFilter.all, child: Text('All Upcoming')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Bar
            _buildQuickActions(context, auth.isOwner),
            const SizedBox(height: 24),

            // Financial Summary Widgets (Strictly OWNER ONLY)
            if (auth.isOwner) ...[
              const Text('Financial Highlights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildOwnerFinancialWidgets(),
              const SizedBox(height: 24),
            ],

            // Operational Metrics (Both Owner and Manager)
            const Text('Operational Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            ordersAsync.when(
              data: (orders) {
                final now = DateTime.now();
                final dueCount = orders.where((o) {
                  return o.deliveryDate.year == now.year &&
                      o.deliveryDate.month == now.month &&
                      o.deliveryDate.day == now.day;
                }).length;

                final pendingCount = orders.where((o) => o.status.name != 'completed').length;
                final urgentCount = orders.where((o) => o.isUrgent && o.status.name != 'completed').length;

                return Row(
                  children: [
                    _metricCard('Orders Due Today', '$dueCount', Icons.calendar_today, Colors.blue),
                    const SizedBox(width: 12),
                    _metricCard('Active In-Flight', '$pendingCount', Icons.pending_actions, AppColors.primaryWine),
                    const SizedBox(width: 12),
                    _metricCard('Urgent Rush', '$urgentCount', Icons.notification_important, Colors.red.shade700),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading orders: $e'),
            ),

            const SizedBox(height: 24),

            // Rental Returns
            const Text('Upcoming Rental Returns',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            rentalsAsync.when(
              data: (rentals) {
                final pendingReturns =
                    rentals.where((r) => r.status.name == 'rented').take(3).toList();

                if (pendingReturns.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No garments currently rented out.'),
                    ),
                  );
                }

                return Column(
                  children: pendingReturns.map((r) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFBE9E7),
                          child: Icon(Icons.checkroom, color: AppColors.primaryWine),
                        ),
                        title: Text('Customer: ${r.customerId}'),
                        subtitle: Text(
                            'Return Due: ${r.returnDate.day}/${r.returnDate.month}/${r.returnDate.year}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/rentals'),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading rentals: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isOwner) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionChip(context, Icons.person_add, 'New Customer', () => context.push('/customers/new')),
          const SizedBox(width: 8),
          _actionChip(context, Icons.add_shopping_cart, 'New Order', () => context.push('/orders/new')),
          const SizedBox(width: 8),
          _actionChip(context, Icons.payments, 'Record Payment', () => context.go('/payments')),
          const SizedBox(width: 8),
          _actionChip(context, Icons.checkroom, 'New Rental', () => context.go('/rentals')),
          if (isOwner) ...[
            const SizedBox(width: 8),
            _actionChip(context, Icons.school, 'Classes Hub', () => context.go('/classes')),
          ],
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primaryWine),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.ivorySurface,
      onPressed: onTap,
    );
  }

  Widget _buildOwnerFinancialWidgets() {
    final paymentsAsync = ref.watch(ownerPaymentsProvider);

    return paymentsAsync.when(
      data: (payments) {
        final now = DateTime.now();
        final todayPayments = payments.where((p) {
          return p.paymentDate.year == now.year &&
              p.paymentDate.month == now.month &&
              p.paymentDate.day == now.day;
        }).fold(0.0, (acc, p) => acc + p.amount);

        final totalCollections = payments.fold(0.0, (acc, p) => acc + p.amount);

        return Row(
          children: [
            _metricCard('Today\'s Collections', '₹${todayPayments.toStringAsFixed(0)}',
                Icons.trending_up, Colors.green.shade800),
            const SizedBox(width: 12),
            _metricCard('Total Cumulative', '₹${totalCollections.toStringAsFixed(0)}',
                Icons.account_balance, AppColors.goldDark),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor)),
          ],
        ),
      ),
    );
  }
}
