import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(orderStatusFilterProvider);
    final ordersAsync = ref.watch(filteredOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(filteredOrdersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Order'),
        onPressed: () => context.push('/orders/new'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Order # or Notes...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryWine),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => ref.read(orderSearchQueryProvider.notifier).state = '',
                ),
              ),
              onChanged: (val) => ref.read(orderSearchQueryProvider.notifier).state = val,
            ),
          ),

          // Status Filter Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Orders'),
                  selected: statusFilter == null,
                  onSelected: (_) => ref.read(orderStatusFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(_formatStatus(status.name)),
                      selected: statusFilter == status,
                      onSelected: (selected) {
                        ref.read(orderStatusFilterProvider.notifier).state = selected ? status : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Orders List View
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No orders matching criteria', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading orders: $err')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String s) {
    return s.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').capitalize();
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.ivorySurface,
          foregroundColor: AppColors.primaryWine,
          child: const Icon(Icons.receipt, size: 20),
        ),
        title: Row(
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.status.toDbString().toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(order.status),
                ),
              ),
            ),
            if (order.isUrgent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusError),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.customerName.isNotEmpty)
                Text(
                  order.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryWine),
                ),
              Text('${order.items.length} item(s) • Total: ₹${order.totalAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 2),
              Text(
                'Due: ${_formatDate(order.deliveryDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => context.push('/orders/${order.id}', extra: order),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Colors.blue.shade700;
      case OrderStatus.inProgress:
        return AppColors.primaryWine;
      case OrderStatus.ready:
      case OrderStatus.delivered:
        return AppColors.statusSuccess;
      case OrderStatus.cancelled:
        return AppColors.statusError;
      default:
        return AppColors.goldDark;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
