import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animated_button.dart';
import '../../core/utils/validation_helpers.dart';
import '../../core/utils/unfocus_wrapper.dart';
import '../../data/models/expense.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/edit_expense_viewmodel.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/utils/image_helper.dart';
import '../../viewmodels/settings_viewmodel.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _commentController;
  late String _category;
  late String _photoPath;
  late DateTime _selectedDate;

  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Bills', 'Other'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _commentController = TextEditingController(text: widget.expense.comment);
    _category = widget.expense.category;
    _photoPath = widget.expense.photoPath;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final savedPath = await ImageHelper.saveImageLocally(pickedFile);
        if (savedPath != null) {
          setState(() => _photoPath = savedPath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final settingsVm = Provider.of<SettingsViewModel>(context, listen: false);
      if (settingsVm.requirePhoto && _photoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo is required based on your settings.')));
        return;
      }

      final expensesVm = Provider.of<ExpensesListViewModel>(context, listen: false);
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);
      final editVm = EditExpenseViewModel(expensesVm: expensesVm, homeVm: homeVm);

      final updated = Expense(
        id: widget.expense.id,
        amount: double.parse(_amountController.text.trim()),
        category: _category,
        comment: _commentController.text.trim(),
        photoPath: _photoPath,
        date: _selectedDate,
        currency: widget.expense.currency,
      );

      await editVm.updateExpense(updated, widget.expense.amount);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Expense')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: ValidationHelpers.validateAmount,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
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
                      lastDate: DateTime.now(), // Validation: not in future
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
                  maxLines: 3,
                  validator: ValidationHelpers.validateOptionalText,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Photo Fixation', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _photoPath.isEmpty && widget.expense.photoPath.isEmpty
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
                            child: _photoPath.isNotEmpty
                                ? Image.file(
                                    File(_photoPath),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: double.infinity, height: 200,
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      child: const Center(child: Icon(Icons.broken_image, color: AppColors.error)),
                                    ),
                                  )
                                : Image.file(
                                    File(widget.expense.photoPath),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: double.infinity, height: 200,
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      child: const Center(child: Icon(Icons.broken_image, color: AppColors.error)),
                                    ),
                                  ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
