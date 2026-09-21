import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/measurement_repository.dart';
import '../../../domain/models/measurement_model.dart';
import '../../providers/measurement_provider.dart';

class MeasurementEntryScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final MeasurementSet? initialSet;

  const MeasurementEntryScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.initialSet,
  });

  @override
  ConsumerState<MeasurementEntryScreen> createState() => _MeasurementEntryScreenState();
}

class _MeasurementEntryScreenState extends ConsumerState<MeasurementEntryScreen> {
  MeasurementTemplate? _selectedTemplate;
  final Map<String, TextEditingController> _fieldControllers = {};
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSet != null) {
      _notesController.text = widget.initialSet!.notes ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _initControllersForTemplate(MeasurementTemplate template) {
    _selectedTemplate = template;
    for (final field in template.fields) {
      final initialVal = widget.initialSet != null && widget.initialSet!.garmentType == template.garmentType
          ? widget.initialSet!.values[field.id]?.toString() ?? ''
          : '';
      if (!_fieldControllers.containsKey(field.id)) {
        _fieldControllers[field.id] = TextEditingController(text: initialVal);
      } else if (initialVal.isNotEmpty && _fieldControllers[field.id]!.text.isEmpty) {
        _fieldControllers[field.id]!.text = initialVal;
      }
    }
  }

  Future<void> _saveMeasurements() async {
    if (_selectedTemplate == null) return;

    final currentUnit = ref.read(measurementUnitProvider);
    final values = <String, double>{};

    for (final field in _selectedTemplate!.fields) {
      final text = _fieldControllers[field.id]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          values[field.id] = parsed;
        }
      }
    }

    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one measurement value.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(measurementControllerProvider.notifier).saveMeasurementSet(
            customerId: widget.customerId,
            templateId: _selectedTemplate!.id,
            garmentType: _selectedTemplate!.garmentType,
            values: values,
            displayUnit: currentUnit,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving measurements: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(measurementTemplatesProvider);
    final currentUnit = ref.watch(measurementUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Measurement', style: TextStyle(fontSize: 18)),
            Text(widget.customerName, style: const TextStyle(fontSize: 13, color: AppColors.goldLight)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveMeasurements,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save Measurement Set'),
        ),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('No measurement templates configured.'));
          }

          if (_selectedTemplate == null) {
            _initControllersForTemplate(templates.first);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template Selector & Unit Switcher Row
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Garment Template', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<MeasurementTemplate>(
                                initialValue: _selectedTemplate,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: templates
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.garmentType),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _initControllersForTemplate(val));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Unit Toggle (Inches vs CM)
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'inches', label: Text('Inches')),
                                ButtonSegment(value: 'cm', label: Text('CM')),
                              ],
                              selected: {currentUnit},
                              onSelectionChanged: (set) {
                                final newUnit = set.first;
                                // Automatically convert existing field values on unit change
                                for (final field in _selectedTemplate!.fields) {
                                  final text = _fieldControllers[field.id]?.text.trim() ?? '';
                                  if (text.isNotEmpty) {
                                    final currentVal = double.tryParse(text);
                                    if (currentVal != null) {
                                      if (newUnit == 'cm') {
                                        _fieldControllers[field.id]?.text =
                                            MeasurementUnitConverter.inchesToCm(currentVal).toString();
                                      } else {
                                        _fieldControllers[field.id]?.text =
                                            MeasurementUnitConverter.cmToInches(currentVal).toString();
                                      }
                                    }
                                  }
                                }
                                ref.read(measurementUnitProvider.notifier).state = newUnit;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fast High-Speed Numeric Measurement Fields Grid
                const Text('Enter Measurements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_selectedTemplate != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedTemplate!.fields.length,
                    itemBuilder: (context, index) {
                      final field = _selectedTemplate!.fields[index];
                      final controller = _fieldControllers[field.id]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                field.label,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: index < _selectedTemplate!.fields.length - 1
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  suffixText: currentUnit == 'inches' ? 'in' : 'cm',
                                  suffixStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // Measurement Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Measurement Notes / Fitting Remarks',
                    hintText: 'e.g. Loose armhole requested, padded cups...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
