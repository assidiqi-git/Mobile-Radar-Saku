import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_category_provider.dart';
import '../../providers/transaction_type_provider.dart';

class TransactionCategoryFormScreen extends StatefulWidget {
  /// Pass [category] to open in edit mode; null = create mode.
  final TransactionCategoryModel? category;

  const TransactionCategoryFormScreen({super.key, this.category});

  @override
  State<TransactionCategoryFormScreen> createState() =>
      _TransactionCategoryFormScreenState();
}

class _TransactionCategoryFormScreenState
    extends State<TransactionCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  TransactionTypeModel? _selectedType;
  bool _isSaving = false;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');

    // Load types and pre-select if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final typeProvider = context.read<TransactionTypeProvider>();
      if (typeProvider.types.isEmpty) {
        typeProvider.loadAll().then((_) => _preselectType());
      } else {
        _preselectType();
      }
    });
  }

  void _preselectType() {
    if (!mounted) return;
    if (widget.category == null) return;

    final types = context.read<TransactionTypeProvider>().types;
    final match = types.where((t) => t.id == widget.category!.transactionTypeId).firstOrNull;
    if (match != null) {
      setState(() => _selectedType = match);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---- Helpers --------------------------------------------------------------

  Color _actionColor(String? action) {
    switch (action) {
      case AppConstants.actionAddition:
        return AppTheme.incomeColor;
      case AppConstants.actionDeduction:
        return AppTheme.expenseColor;
      default:
        return AppTheme.outline;
    }
  }

  String _actionLabel(String? action) {
    switch (action) {
      case AppConstants.actionAddition:
        return 'Penambahan';
      case AppConstants.actionDeduction:
        return 'Pengurangan';
      default:
        return 'Netral';
    }
  }

  // ---- Save -----------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tipe transaksi terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final catProvider = context.read<TransactionCategoryProvider>();
      final trimmedName = _nameController.text.trim();
      final trimmedDesc = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (_isEditMode) {
        await catProvider.update(
          widget.category!.id,
          transactionTypeId: _selectedType!.id,
          name: trimmedName,
          description: trimmedDesc,
          typeModel: _selectedType,
        );
      } else {
        await catProvider.add(
          transactionTypeId: _selectedType!.id,
          name: trimmedName,
          description: trimmedDesc,
          typeModel: _selectedType,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---- Delete ---------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus kategori ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TransactionCategoryProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      setState(() => _isSaving = true);
      try {
        await provider.delete(widget.category!.id);
        if (mounted) navigator.pop(true);
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
            _isEditMode ? 'Edit Kategori' : 'Kategori Baru'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              onPressed: _isSaving ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Tipe Transaksi dropdown
            _buildSectionLabel('Tipe Transaksi *'),
            const SizedBox(height: 8),
            _buildTypeDropdown(),

            const SizedBox(height: 24),

            // Name field
            _buildSectionLabel('Nama Kategori *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'cth. Makan & Minum, Gaji, Belanja',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama kategori wajib diisi';
                }
                if (v.trim().length > AppConstants.maxNameLength) {
                  return 'Nama maksimal ${AppConstants.maxNameLength} karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Description field
            _buildSectionLabel('Deskripsi (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Catatan singkat tentang kategori ini...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 36),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditMode ? 'Simpan Perubahan' : 'Tambah Kategori'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Consumer<TransactionTypeProvider>(
      builder: (context, typeProvider, _) {
        final types = typeProvider.types;

        if (typeProvider.isLoading) {
          return Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (types.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada tipe transaksi. Buat tipe terlebih dahulu.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.error),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<TransactionTypeModel>(
          // ignore: deprecated_member_use
          value: _selectedType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
            hintText: 'Pilih tipe transaksi',
          ),
          items: types.map((type) {
            final color = _actionColor(type.action);
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(type.name),
                  const SizedBox(width: 8),
                  Text(
                    '(${_actionLabel(type.action)})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value),
          validator: (_) =>
              _selectedType == null ? 'Pilih tipe transaksi' : null,
        );
      },
    );
  }
}
