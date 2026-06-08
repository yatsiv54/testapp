import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animated_button.dart';
import '../../core/utils/validation_helpers.dart';
import '../../core/utils/unfocus_wrapper.dart';
import '../../data/models/expense.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/utils/image_helper.dart';

class CreateExpenseScreen extends StatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _commentController;
  late String _category;
  late String _photoPath;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Bills', 'Other'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _commentController = TextEditingController();
    _category = 'Food';
    _photoPath = '';
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    final settings = Provider.of<SettingsViewModel>(context, listen: false);
    
    if (_formKey.currentState!.validate()) {
      if (settings.requirePhoto && _photoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is required according to Settings.')),
        );
        return;
      }
      
      final vm = Provider.of<ExpensesListViewModel>(context, listen: false);
      
      final settingsVm = Provider.of<SettingsViewModel>(context, listen: false);
        final expense = Expense(
          id: const Uuid().v4(),
          amount: double.parse(_amountController.text.trim()),
          category: _category,
          comment: _commentController.text.trim(),
          photoPath: _photoPath,
          date: _selectedDate,
          currency: settingsVm.currency,
        );
        await vm.addExpense(expense);
      
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final path = await ImageHelper.saveImageLocally(picked);
                          if (path != null) {
                            setState(() {
                              _photoPath = path;
                            });
                          }
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _photoPath.isEmpty ? AppColors.border : AppColors.primaryAccent,
                          width: _photoPath.isEmpty ? 2 : 3,
                        ),
                        image: (_photoPath.isNotEmpty && File(_photoPath).existsSync() && File(_photoPath).lengthSync() > 0)
                            ? DecorationImage(
                                image: FileImage(File(_photoPath)),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.2),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        boxShadow: [
                          if (_photoPath.isNotEmpty)
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                        ],
                      ),
                      child: (_photoPath.isEmpty || !File(_photoPath).existsSync() || File(_photoPath).lengthSync() == 0)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 40,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Tap to capture receipt', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_photoPath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: AppColors.error, size: 48),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: ValidationHelpers.validateAmount,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(), // Date validation: cannot be in the future
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return ValidationHelpers.validateText(value);
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Comment (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  onPressed: _saveExpense,
                  child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
