import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animated_button.dart';
import '../../core/utils/validation_helpers.dart';
import '../../core/utils/unfocus_wrapper.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'main_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_helper.dart';

class ProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  const ProfileScreen({super.key, this.isInitialSetup = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  String _photoPath = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isInitialSetup) {
        final homeVm = Provider.of<HomeViewModel>(context, listen: false);
        if (homeVm.profile != null) {
          setState(() {
            _nameController.text = homeVm.profile!.name;
            _limitController.text = homeVm.profile!.dailyLimit.toString();
            _photoPath = homeVm.profile!.photoPath;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final vm = Provider.of<ProfileViewModel>(context, listen: false);
      await vm.saveProfile(
        _nameController.text.trim(),
        double.parse(_limitController.text.trim()),
        _photoPath,
      );
      if (!mounted) return;
      Provider.of<HomeViewModel>(context, listen: false).loadData();

      if (widget.isInitialSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _skip() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ProfileViewModel>(context);

    return UnfocusWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            if (widget.isInitialSetup)
              TextButton(
                onPressed: _skip,
                child: const Text('Skip'),
              )
          ],
        ),
        body: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                              if (pickedFile != null) {
                                final path = await ImageHelper.saveImageLocally(pickedFile.path);
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
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).cardColor,
                            backgroundImage: _photoPath.isNotEmpty
                                ? FileImage(File(_photoPath))
                                : null,
                            child: _photoPath.isEmpty
                                ? const Icon(Icons.add_a_photo,
                                    size: 40, color: AppColors.primaryAccent)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        validator: ValidationHelpers.validateOptionalText,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: ValidationHelpers.validateAmount,
                        decoration: const InputDecoration(
                          labelText: 'Daily Limit',
                          border: OutlineInputBorder(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 32),
                      AnimatedButton(
                        onPressed: _saveProfile,
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.isInitialSetup) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                            );
                          },
                          child: Text('Skip for now',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
