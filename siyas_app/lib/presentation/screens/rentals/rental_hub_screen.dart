import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/rental_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';

class RentalHubScreen extends ConsumerStatefulWidget {
  const RentalHubScreen({super.key});

  @override
  ConsumerState<RentalHubScreen> createState() => _RentalHubScreenState();
}

class _RentalHubScreenState extends ConsumerState<RentalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditItemDialog(BuildContext context, [RentalItem? existing]) {
    final codeCtrl = TextEditingController(text: existing?.itemCode ?? '');
    final nameCtrl = TextEditingController(text: existing?.itemName ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? 'Bridal Lehengas');
    final sizeCtrl = TextEditingController(text: existing?.size ?? 'M');
    final colourCtrl = TextEditingController(text: existing?.colour ?? 'Red');
    final priceCtrl =
        TextEditingController(text: existing != null ? existing.rentalPrice.toStringAsFixed(0) : '');
    final depositCtrl =
        TextEditingController(text: existing != null ? existing.deposit.toStringAsFixed(0) : '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Rental Item' : 'Edit Rental Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Item Code (e.g. HS-REN-0001)'),
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(labelText: 'Size'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: colourCtrl,
                          decoration: const InputDecoration(labelText: 'Colour'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rent Rate (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: depositCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Deposit (₹)'),
                        ),
                      ),
                    ],
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
                        final code = codeCtrl.text.trim();
                        final name = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                        final deposit = double.tryParse(depositCtrl.text.trim()) ?? 0.0;

                        if (code.isEmpty || name.isEmpty || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final item = RentalItem(
                            id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            itemCode: code,
                            itemName: name,
                            category: catCtrl.text.trim(),
                            size: sizeCtrl.text.trim(),
                            colour: colourCtrl.text.trim(),
                            rentalPrice: price,
                            deposit: deposit,
                            isActive: true,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await ref.read(rentalControllerProvider.notifier).saveRentalItem(item);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
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
                    : const Text('Save Item'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNewBookingDialog(BuildContext context) {
    final itemsAsync = ref.read(rentalItemsProvider);
    final items = itemsAsync.asData?.value.where((i) => i.isActive).toList() ?? [];

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add rental items to catalogue first.')),
      );
      return;
    }

    String selectedItemId = items.first.id;
    final customerCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 3));
    final rentCtrl = TextEditingController(text: items.first.rentalPrice.toStringAsFixed(0));
    final depCtrl = TextEditingController(text: items.first.deposit.toStringAsFixed(0));
    final paidCtrl = TextEditingController(text: items.first.rentalPrice.toStringAsFixed(0));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('New Rental Booking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Item',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  DropdownButton<String>(
                    value: selectedItemId,
                    isExpanded: true,
                    items: items.map((it) {
                      return DropdownMenuItem(
                        value: it.id,
                        child: Text('${it.itemCode} - ${it.itemName} (${it.size})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedItemId = val;
                          final it = items.firstWhere((i) => i.id == val);
                          rentCtrl.text = it.rentalPrice.toStringAsFixed(0);
                          depCtrl.text = it.deposit.toStringAsFixed(0);
                          paidCtrl.text = it.rentalPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(labelText: 'Customer ID / Name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                          child: Text(
                              'Start: ${startDate.day}/${startDate.month}/${startDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: returnDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => returnDate = picked);
                            }
                          },
                          child: Text(
                              'Return: ${returnDate.day}/${returnDate.month}/${returnDate.year}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rent (₹)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: depCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Deposit (₹)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Advance Paid (₹)'),
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
                        final customer = customerCtrl.text.trim();
                        final rent = double.tryParse(rentCtrl.text.trim()) ?? 0.0;
                        final dep = double.tryParse(depCtrl.text.trim()) ?? 0.0;
                        final paid = double.tryParse(paidCtrl.text.trim()) ?? 0.0;

                        if (customer.isEmpty || rent <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid customer and rent.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final tx = RentalTransaction(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            rentalItemId: selectedItemId,
                            customerId: customer,
                            rentalStartDate: startDate,
                            returnDate: returnDate,
                            rentalAmount: rent,
                            depositAmount: dep,
                            paidAmount: paid,
                            status: RentalStatus.reserved,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            createdBy: ref.read(authProvider).uid ?? 'staff',
                          );

                          await ref
                              .read(rentalControllerProvider.notifier)
                              .createRentalTransaction(tx);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rental booking confirmed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
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
                    : const Text('Confirm Booking'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(authProvider).isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add_business),
              tooltip: 'Add Catalogue Item',
              onPressed: () => _showAddEditItemDialog(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldDark,
          labelColor: AppColors.primaryWine,
          tabs: const [
            Tab(text: 'Active Bookings'),
            Tab(text: 'Catalogue & Items'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bookmark_add),
        label: const Text('New Booking'),
        onPressed: () => _showNewBookingDialog(context),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab(),
          _buildCatalogueTab(isOwner),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final rentalsAsync = ref.watch(rentalTransactionsProvider);

    return rentalsAsync.when(
      data: (rentals) {
        if (rentals.isEmpty) {
          return const Center(child: Text('No rental bookings recorded yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rentals.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final r = rentals[idx];
            final isReturned = r.status == RentalStatus.returned;
            final isOverdue =
                !isReturned && DateTime.now().isAfter(r.returnDate) && r.status == RentalStatus.rented;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isReturned
                    ? Colors.grey.shade200
                    : (isOverdue ? Colors.red.shade100 : AppColors.goldDark.withValues(alpha: 0.15)),
                child: Icon(
                  Icons.checkroom,
                  color: isReturned
                      ? Colors.grey
                      : (isOverdue ? Colors.red.shade800 : AppColors.goldDark),
                ),
              ),
              title: Text('Customer: ${r.customerId}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Rent: ₹${r.rentalAmount.toStringAsFixed(0)} | Deposit: ₹${r.depositAmount.toStringAsFixed(0)}\nDue: ${r.returnDate.day}/${r.returnDate.month}/${r.returnDate.year} • Status: ${r.status.name.toUpperCase()}',
              ),
              trailing: PopupMenuButton<RentalStatus>(
                onSelected: (newStatus) async {
                  await ref.read(rentalControllerProvider.notifier).updateRentalStatus(
                        transaction: r,
                        newStatus: newStatus,
                        depositReturned: newStatus == RentalStatus.returned ? r.depositAmount : 0.0,
                      );
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: RentalStatus.rented,
                    child: Text('Mark Rented / Picked Up'),
                  ),
                  const PopupMenuItem(
                    value: RentalStatus.returned,
                    child: Text('Mark Returned & Refund Deposit'),
                  ),
                  const PopupMenuItem(
                    value: RentalStatus.cancelled,
                    child: Text('Cancel Booking'),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading rentals: $e')),
    );
  }

  Widget _buildCatalogueTab(bool isOwner) {
    final itemsAsync = ref.watch(rentalItemsProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No rental items in catalogue.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final item = items[idx];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFBE9E7),
                child: const Icon(Icons.checkroom, color: AppColors.primaryWine),
              ),
              title: Text('${item.itemCode}: ${item.itemName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${item.category} • Size: ${item.size} • Colour: ${item.colour}\nRent: ₹${item.rentalPrice.toStringAsFixed(0)} | Deposit: ₹${item.deposit.toStringAsFixed(0)}',
              ),
              trailing: isOwner
                  ? IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showAddEditItemDialog(context, item),
                    )
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading items: $e')),
    );
  }
}
