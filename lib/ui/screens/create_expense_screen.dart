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
                GestureDetector(
                  onTap: () async {
                    try {
                      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (picked != null) {
                        final path = await ImageHelper.saveImageLocally(picked.path);
                        if (path != null) {
                          setState(() {
                            _photoPath = path;
                          });
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: _photoPath.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt, size: 48, color: AppColors.primaryAccent),
                                const SizedBox(height: 16),
                                Text('Tap to capture receipt', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(_photoPath), fit: BoxFit.cover, width: double.infinity),
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
