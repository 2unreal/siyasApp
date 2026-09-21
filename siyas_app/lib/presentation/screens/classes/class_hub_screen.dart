import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';

class ClassHubScreen extends ConsumerStatefulWidget {
  const ClassHubScreen({super.key});

  @override
  ConsumerState<ClassHubScreen> createState() => _ClassHubScreenState();
}

class _ClassHubScreenState extends ConsumerState<ClassHubScreen> {
  void _showEnrollStudentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final courseCtrl = TextEditingController(text: 'Aari & Zardozi Embroidery');
    final feeCtrl = TextEditingController(text: '12000');
    final advanceCtrl = TextEditingController(text: '5000');
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Enroll New Student'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Student Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile Number'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: courseCtrl.text,
                    decoration: const InputDecoration(labelText: 'Course / Program'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Aari & Zardozi Embroidery',
                          child: Text('Aari & Zardozi Embroidery')),
                      DropdownMenuItem(
                          value: 'Bridal Blouse Designing',
                          child: Text('Bridal Blouse Designing')),
                      DropdownMenuItem(
                          value: 'Pattern Making & Tailoring',
                          child: Text('Pattern Making & Tailoring')),
                      DropdownMenuItem(
                          value: 'Fabric Painting & Dyeing',
                          child: Text('Fabric Painting & Dyeing')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        courseCtrl.text = val;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Fee (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: advanceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Advance Paid (₹)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (Batch / Schedule)'),
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
                        final name = nameCtrl.text.trim();
                        final mobile = mobileCtrl.text.trim();
                        final fee = double.tryParse(feeCtrl.text.trim()) ?? 0.0;
                        final advance = double.tryParse(advanceCtrl.text.trim()) ?? 0.0;

                        if (name.isEmpty || mobile.isEmpty || fee <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await ref.read(studentControllerProvider.notifier).enrollStudent(
                                studentName: name,
                                mobile: mobile,
                                courseName: courseCtrl.text.trim(),
                                totalFee: fee,
                                advancePaid: advance,
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              );

                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Student enrolled successfully!'),
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
                    : const Text('Enroll Student'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordFeeDialog(BuildContext context, Student student) {
    final amountCtrl = TextEditingController(text: student.balanceFee.toStringAsFixed(0));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text('Record Fee Payment — ${student.studentName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding Balance: ₹${student.balanceFee.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryWine)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryWine,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid positive amount.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await ref.read(studentControllerProvider.notifier).updateStudentFeePayment(
                                student: student,
                                additionalPayment: amt,
                              );
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
                    : const Text('Confirm Fee Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Strict Zero-Trust UI Protection
    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classes & Training')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 72, color: AppColors.primaryWine),
                SizedBox(height: 16),
                Text(
                  'Access Restricted to Business Owner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Class student records and financial fee tracking are protected under Business Owner access permissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Classes & Student Fees')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Enroll Student'),
        onPressed: () => _showEnrollStudentDialog(context),
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students enrolled yet.'));
          }

          final totalCollected = students.fold(0.0, (acc, s) => acc + s.paidFee);
          final totalPending = students.fold(0.0, (acc, s) => acc + s.balanceFee);

          return Column(
            children: [
              // Summary Banner
              Container(
                color: AppColors.ivorySurface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Students', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text('${students.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Collected (₹)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text('₹${totalCollected.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending (₹)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text('₹${totalPending.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryWine)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final student = students[idx];
                    final isCleared = student.balanceFee == 0.0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCleared ? Colors.green.shade100 : AppColors.goldDark.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.school,
                          color: isCleared ? Colors.green.shade900 : AppColors.goldDark,
                        ),
                      ),
                      title: Text(student.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${student.courseName} • Mobile: ${student.mobile}\nPaid: ₹${student.paidFee.toStringAsFixed(0)} / ₹${student.totalFee.toStringAsFixed(0)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCleared)
                            IconButton(
                              icon: const Icon(Icons.add_card, color: AppColors.primaryWine),
                              tooltip: 'Record Payment',
                              onPressed: () => _showRecordFeeDialog(context, student),
                            ),
                          Text(
                            isCleared ? 'PAID' : 'Bal: ₹${student.balanceFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isCleared ? Colors.green : AppColors.primaryWine,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading students: $e')),
      ),
    );
  }
}
