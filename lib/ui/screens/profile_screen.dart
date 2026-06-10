import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/animated_button.dart';
import '../../core/utils/validation_helpers.dart';
import '../../core/utils/unfocus_wrapper.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'main_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_helper.dart';
import '../widgets/loading_shimmer_widget.dart';
import '../widgets/error_state_widget.dart';
class ProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  const ProfileScreen({super.key, this.isInitialSetup = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  String _photoPath = '';

  late final AnimationController _entranceController;
  late final List<Animation<double>> _staggeredFades;
  late final List<Animation<Offset>> _staggeredSlides;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _staggeredFades = List.generate(4, (index) {
      final start = index * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _staggeredSlides = List.generate(4, (index) {
      final start = index * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

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
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _entranceController.dispose();
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

  Future<void> _pickPhoto() async {
    try {
      final path = await ImageHelper.pickImage(context);
      if (path != null) {
        setState(() {
          _photoPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ProfileViewModel>(context);

    Widget body;
    if (vm.isLoading) {
      body = const LoadingShimmerWidget(type: ShimmerType.detail);
    } else if (vm.hasError) {
      body = ErrorStateWidget(
        message: vm.errorMessage ?? 'Failed to load profile',
        onRetry: () => _saveProfile(),
      );
    } else {
      body = _buildContent(context);
    }

    return UnfocusWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: body,
      ),
    );
  }



  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAnimatedItem(
                    index: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryAccent.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Info',
                            style: AppTypography.headline2.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            validator: ValidationHelpers.validateOptionalText,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            style: AppTypography.body.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: AppTypography.body.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryAccent,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _limitController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: ValidationHelpers.validateAmount,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            style: AppTypography.body.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Daily Limit',
                              labelStyle: AppTypography.body.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                ),
                                child: const Icon(
                                  Icons.attach_money_rounded,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryAccent,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    index: 2,
                    child: AnimatedButton(
                      onPressed: _saveProfile,
                      child: Text(
                        'Save Profile',
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isInitialSetup) ...[
                    const SizedBox(height: 12),
                    _buildAnimatedItem(
                      index: 3,
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Skip for now',
                          style: AppTypography.body.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _buildAnimatedItem(
      index: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 32,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent,
              AppColors.secondaryAccent,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (!widget.isInitialSetup)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 56),
                Expanded(
                  child: Text(
                    'Profile',
                    style: AppTypography.headline1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.isInitialSetup)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 56),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Theme.of(context).cardColor,
                      backgroundImage: (_photoPath.isNotEmpty && 
                                        File(_photoPath).existsSync() &&
                                        File(_photoPath).lengthSync() > 0)
                          ? FileImage(File(_photoPath))
                          : null,
                      child: (_photoPath.isEmpty ||
                              !File(_photoPath).existsSync() ||
                              File(_photoPath).lengthSync() == 0)
                          ? const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: AppColors.primaryAccent,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isInitialSetup
                  ? 'Set up your profile'
                  : 'Edit your profile',
              style: AppTypography.caption.copyWith(
                color:
                    Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({
    required int index,
    required Widget child,
  }) {
    final safeIndex = index.clamp(0, _staggeredFades.length - 1);
    return FadeTransition(
      opacity: _staggeredFades[safeIndex],
      child: SlideTransition(
        position: _staggeredSlides[safeIndex],
        child: child,
      ),
    );
  }
}
