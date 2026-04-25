import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_input.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _buyoutPriceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _swapTagController = TextEditingController();

  final _cityController = TextEditingController();

  String _selectedCategory = AppConstants.marketplaceCategories.first;
  String _selectedCondition = AppConstants.conditions.first;
  String _selectedListingType = 'Swap'; // Swap first
  String? _selectedState;
  final List<String> _swapTags = [];
  final List<XFile> _imageFiles = []; // Picked image files
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  static const _listingTypes = ['Swap', 'Sell or Swap', 'Sell'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _buyoutPriceController.dispose();
    _phoneController.dispose();
    _swapTagController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _addSwapTag() {
    final tag = _swapTagController.text.trim();
    if (tag.isEmpty || _swapTags.length >= 8 || _swapTags.contains(tag)) return;
    setState(() {
      _swapTags.add(tag);
      _swapTagController.clear();
    });
  }

  void _removeSwapTag(String tag) {
    setState(() => _swapTags.remove(tag));
  }

  Future<void> _addImage() async {
    if (_imageFiles.length >= 4) return;

    setState(() => _isUploadingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _imageFiles.add(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  bool get _showPriceField =>
      _selectedListingType == 'Sell' || _selectedListingType == 'Sell or Swap';

  bool get _showSwapFields =>
      _selectedListingType == 'Swap' || _selectedListingType == 'Sell or Swap';

  bool get _showBuyoutField => _selectedListingType == 'Swap';

  String _mapListingType(String uiType) {
    switch (uiType) {
      case 'Swap':
        return 'swap';
      case 'Sell':
        return 'sell';
      case 'Sell or Swap':
        return 'sell_or_swap';
      default:
        return 'swap';
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(marketplaceRepositoryProvider);

      // Upload images first
      final List<String> imageUrls = [];
      for (final file in _imageFiles) {
        final bytes = await File(file.path).readAsBytes();
        final baseName = file.path.split('/').last.split('\\').last;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$baseName';
        final url = await repo.uploadImage(fileName, bytes);
        imageUrls.add(url);
      }

      // Build listing data
      final city = _cityController.text.trim();
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'listing_type': _mapListingType(_selectedListingType),
        'images': imageUrls,
        'swap_for_tags': _swapTags,
        'status': 'active',
        'location_state': _selectedState,
        if (city.isNotEmpty) 'location_city': city,
        'location': [city, _selectedState].where((s) => s != null && s.isNotEmpty).join(', '),
      };

      if (_showPriceField && _priceController.text.isNotEmpty) {
        data['price'] = int.tryParse(_priceController.text.trim());
      }

      if (_showBuyoutField && _buyoutPriceController.text.isNotEmpty) {
        data['buyout_price'] =
            int.tryParse(_buyoutPriceController.text.trim());
      }

      await repo.createListing(data);

      // Invalidate listings so they refresh when user navigates back
      ref.invalidate(listingsProvider);
      ref.invalidate(myListingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create listing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Listing'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Photos ──────────────────────────────
            Text('Photos', style: AppTypography.subheading),
            const SizedBox(height: 4),
            Text(
              'Add up to 4 photos. First photo is the cover.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageFiles.asMap().entries.map((entry) => Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                File(entry.value.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.image,
                                          size: 24,
                                          color: AppColors.textMuted),
                                      const SizedBox(height: 4),
                                      Text('${entry.key + 1}',
                                          style: AppTypography.labelSmall),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.x,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (_imageFiles.length < 4)
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _addImage,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus,
                                      size: 24, color: AppColors.cyan),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style:
                                        AppTypography.labelSmall.copyWith(
                                      color: AppColors.cyan,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ───────────────────────────────
            CgeInput(
              label: 'Title',
              hint: 'e.g. PS5 DualSense Controller',
              controller: _titleController,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ─────────────────────────
            CgeInput(
              label: 'Description',
              hint: 'Describe your item, condition, and any extras...',
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Condition ───────────────────────────
            Text('Condition', style: AppTypography.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.conditions
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _selectedCondition == c,
                        selectedColor:
                            AppColors.cyan.withValues(alpha: 0.2),
                        onSelected: (_) =>
                            setState(() => _selectedCondition = c),
                        side: BorderSide(
                          color: _selectedCondition == c
                              ? AppColors.cyan
                              : AppColors.border,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ── Category ────────────────────────────
            Text('Category', style: AppTypography.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.marketplaceCategories
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _selectedCategory == c,
                        selectedColor:
                            AppColors.cyan.withValues(alpha: 0.2),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = c),
                        side: BorderSide(
                          color: _selectedCategory == c
                              ? AppColors.cyan
                              : AppColors.border,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ── Listing Type ────────────────────────
            Text('Listing Type', style: AppTypography.label),
            const SizedBox(height: 4),
            Text(
              'Swap is the default — the CGE way!',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.magenta, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: _listingTypes
                  .map((type) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: type != _listingTypes.last ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedListingType = type),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedListingType == type
                                    ? (type == 'Swap'
                                        ? AppColors.magenta
                                            .withValues(alpha: 0.15)
                                        : type == 'Sell'
                                            ? AppColors.cyan
                                                .withValues(alpha: 0.15)
                                            : AppColors.gold
                                                .withValues(alpha: 0.15))
                                    : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedListingType == type
                                      ? (type == 'Swap'
                                          ? AppColors.magenta
                                          : type == 'Sell'
                                              ? AppColors.cyan
                                              : AppColors.gold)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                type,
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  fontSize: 12,
                                  color: _selectedListingType == type
                                      ? (type == 'Swap'
                                          ? AppColors.magenta
                                          : type == 'Sell'
                                              ? AppColors.cyan
                                              : AppColors.gold)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ── Swap wants ──────────────────────────
            if (_showSwapFields) ...[
              Text('What would you swap for?',
                  style: AppTypography.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _swapTagController,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: 'e.g. Gaming Headset',
                        hintStyle: AppTypography.body
                            .copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.cyan),
                        ),
                      ),
                      onSubmitted: (_) => _addSwapTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CgeButton(
                    label: 'Add',
                    onPressed: _addSwapTag,
                    size: CgeButtonSize.sm,
                  ),
                ],
              ),
              if (_swapTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _swapTags
                      .map((tag) => Chip(
                            label: Text(
                              tag,
                              style: AppTypography.label.copyWith(
                                color: AppColors.magenta,
                                fontSize: 11,
                              ),
                            ),
                            deleteIcon:
                                const Icon(LucideIcons.x, size: 14),
                            deleteIconColor: AppColors.magenta,
                            onDeleted: () => _removeSwapTag(tag),
                            backgroundColor: AppColors.magenta
                                .withValues(alpha: 0.1),
                            side: BorderSide(
                              color: AppColors.magenta
                                  .withValues(alpha: 0.3),
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (_swapTags.length < 8)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${8 - _swapTags.length} tags remaining',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Suggestions
              if (_swapTags.length < 8) ...[
                Text(
                  'Suggestions:',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.swapSuggestions
                      .where((s) => !_swapTags.contains(s))
                      .take(6)
                      .map((s) => GestureDetector(
                            onTap: () {
                              if (_swapTags.length < 8) {
                                setState(() => _swapTags.add(s));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '+ $s',
                                style: AppTypography.labelSmall
                                    .copyWith(fontSize: 10),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // ── Buyout price (swap only) ────────────
            if (_showBuyoutField) ...[
              CgeInput(
                label: 'Buyout Price (optional)',
                hint: 'Set a price if buyer wants to buy outright',
                controller: _buyoutPriceController,
                prefixIcon: LucideIcons.banknote,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // ── Price ───────────────────────────────
            if (_showPriceField) ...[
              CgeInput(
                label: 'Price (\u20A6)',
                hint: 'Enter price in Naira',
                controller: _priceController,
                prefixIcon: LucideIcons.banknote,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  if (int.tryParse(v) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Phone (WhatsApp) ────────────────────
            CgeInput(
              label: 'Phone Number (for WhatsApp)',
              hint: '+234...',
              controller: _phoneController,
              prefixIcon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // ── Location ─────────────────────────────
            Text('Location', style: AppTypography.subheading),
            const SizedBox(height: 4),
            Text(
              'Helps buyers and swappers know if you\'re nearby.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedState,
                        hint: Text(
                          'Select state',
                          style: AppTypography.body
                              .copyWith(color: AppColors.textMuted),
                        ),
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceAlt,
                        style: AppTypography.body
                            .copyWith(color: AppColors.text),
                        items: AppConstants.nigerianStates
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CgeInput(
              label: 'City (optional)',
              hint: 'e.g. Bonny Island',
              controller: _cityController,
              prefixIcon: LucideIcons.building,
            ),
            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────
            CgeButton(
              label: 'Create Listing',
              onPressed: _isSubmitting ? null : _submit,
              fullWidth: true,
              size: CgeButtonSize.lg,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
