import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ExpensesListViewModel>(context);
    final categories = ['Food', 'Transport', 'Entertainment', 'Bills', 'Other'];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.displayMedium),
              TextButton(
                onPressed: () {
                  vm.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: vm.filterCategory,
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
              ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (val) {
              vm.setFilterCategory(val);
            },
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<bool>(
            initialValue: vm.filterHasPhoto,
            items: const [
              DropdownMenuItem<bool>(value: null, child: Text('Any')),
              DropdownMenuItem<bool>(value: true, child: Text('Has Photo')),
              DropdownMenuItem<bool>(value: false, child: Text('No Photo')),
            ],
            onChanged: (val) {
              vm.setFilterHasPhoto(val);
            },
            decoration: const InputDecoration(labelText: 'Photo Filter', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date Range'),
            subtitle: Text(
              vm.filterDateRange != null
                  ? '${DateFormat('MMM dd').format(vm.filterDateRange!.start)} - ${DateFormat('MMM dd').format(vm.filterDateRange!.end)}'
                  : 'Any Date',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: vm.filterDateRange,
              );
              if (range != null) {
                vm.setFilterDateRange(range);
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
