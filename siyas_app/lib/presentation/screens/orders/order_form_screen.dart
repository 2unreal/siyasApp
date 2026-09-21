import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/order_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final Customer? preselectedCustomer;

  const OrderFormScreen({super.key, this.preselectedCustomer});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  Customer? _selectedCustomer;
  final List<OrderItem> _items = [];
  final _discountController = TextEditingController(text: '0');
  final _generalNoteController = TextEditingController();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isUrgent = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _discountController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _totalAmount => (_subtotal - _discount).clamp(0.0, double.infinity);

  void _showAddLineItemDialog(List<ServiceItem> services) {
    ServiceItem selectedService = services.first;
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController(text: selectedService.defaultPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Order Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ServiceItem>(
                    initialValue: selectedService,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: services
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedService = val;
                          rateController.text = val.defaultPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Description / Notes',
                      hintText: 'e.g. Silk fabric, gold zari neckline',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Rate (₹)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                  final rate = double.tryParse(rateController.text.trim()) ?? selectedService.defaultPrice;
                  final lineTotal = qty * rate;

                  setState(() {
                    _items.add(OrderItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      serviceName: selectedService.name,
                      description: descController.text.trim(),
                      quantity: qty,
                      unitRate: rate,
                      lineTotal: lineTotal,
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add Item'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or link a customer.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(orderControllerProvider.notifier).createOrder(
            customerId: _selectedCustomer!.id,
            customerName: _selectedCustomer!.name,
            customerMobile: _selectedCustomer!.mobile,
            items: _items,
            subtotal: _subtotal,
            discount: _discount,
            totalAmount: _totalAmount,
            deliveryDate: _deliveryDate,
            isUrgent: _isUrgent,
            generalNote: _generalNoteController.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Payable', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _submitOrder,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Order'),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_selectedCustomer != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryWine,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_selectedCustomer!.customerId} • ${_selectedCustomer!.mobile ?? 'No phone'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.change_circle_outlined),
                          onPressed: () => setState(() => _selectedCustomer = null),
                        ),
                      )
                    else
                      customersAsync.when(
                        data: (customers) {
                          return DropdownButtonFormField<Customer>(
                            decoration: const InputDecoration(hintText: 'Select existing customer'),
                            items: customers
                                .map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.customerId})')))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedCustomer = val),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading customers: $e'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Line Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Services & Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          onPressed: () {
                            servicesAsync.whenData((services) => _showAddLineItemDialog(services));
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: Text('No line items added yet.')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _items[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item.quantity} x ₹${item.unitRate.toStringAsFixed(0)} ${item.description.isNotEmpty ? '• ${item.description}' : ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.statusError),
                                  onPressed: () => setState(() => _items.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing & Discount Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('₹${_subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Discount (₹):'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryWine)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Date & General Note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: AppColors.primaryWine),
                      title: const Text('Target Delivery Date'),
                      subtitle: Text('${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}'),
                      trailing: const Text('Change', style: TextStyle(color: AppColors.primaryWine, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _deliveryDate = picked);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Priority / Urgent Order', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Marks order with urgent priority badge'),
                      value: _isUrgent,
                      activeTrackColor: AppColors.statusError,
                      onChanged: (val) => setState(() => _isUrgent = val),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _generalNoteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Order Remarks / Special Instructions',
                        hintText: 'e.g. Urgent trial required before weekend...',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
