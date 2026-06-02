import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_type_provider.dart';

class TransactionTypeFormScreen extends StatefulWidget {
  /// Pass [type] to open in edit mode; null = create mode.
  final TransactionTypeModel? type;

  const TransactionTypeFormScreen({super.key, this.type});

  @override
  State<TransactionTypeFormScreen> createState() =>
      _TransactionTypeFormScreenState();
}

class _TransactionTypeFormScreenState
    extends State<TransactionTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedAction;
  bool _isSaving = false;

  bool get _isEditMode => widget.type != null;

  static const _actionOptions = <({String value, String label, IconData icon, Color color})>[
    (
      value: AppConstants.actionAddition,
      label: 'Penambahan (Pemasukan)',
      icon: Icons.arrow_upward_rounded,
      color: AppTheme.incomeColor,
    ),
    (
      value: AppConstants.actionDeduction,
      label: 'Pengurangan (Pengeluaran)',
      icon: Icons.arrow_downward_rounded,
      color: AppTheme.expenseColor,
    ),
    (
      value: AppConstants.actionNeutral,
      label: 'Netral (Tidak berpengaruh)',
      icon: Icons.remove_rounded,
      color: AppTheme.outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.type?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.type?.description ?? '');
    _selectedAction = widget.type?.action ?? AppConstants.actionAddition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---- Save -----------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<TransactionTypeProvider>();
      if (_isEditMode) {
        await provider.update(
          widget.type!.id,
          name: _nameController.text.trim(),
          action: _selectedAction,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        await provider.add(
          name: _nameController.text.trim(),
          action: _selectedAction,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
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
        title: const Text('Hapus Tipe Transaksi?'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus tipe transaksi ini? Tindakan ini tidak dapat dibatalkan.'),
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
      final provider = context.read<TransactionTypeProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      setState(() => _isSaving = true);
      try {
        await provider.delete(widget.type!.id);
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
        title: Text(_isEditMode ? 'Edit Tipe Transaksi' : 'Tipe Transaksi Baru'),
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
            // Name field
            _buildSectionLabel('Nama Tipe *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'cth. Pemasukan, Belanja, Tabungan',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                if (v.trim().length > AppConstants.maxNameLength) {
                  return 'Nama maksimal ${AppConstants.maxNameLength} karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Action dropdown
            _buildSectionLabel('Aksi *'),
            const SizedBox(height: 8),
            _buildActionSelector(),

            const SizedBox(height: 24),

            // Description field
            _buildSectionLabel('Deskripsi (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Catatan singkat tentang tipe transaksi ini...',
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
                  : Text(_isEditMode ? 'Simpan Perubahan' : 'Tambah Tipe'),
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

  Widget _buildActionSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        children: _actionOptions.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final isSelected = _selectedAction == opt.value;
          final isLast = i == _actionOptions.length - 1;

          return InkWell(
            onTap: () => setState(() => _selectedAction = opt.value),
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(7) : Radius.zero,
              bottom: isLast ? const Radius.circular(7) : Radius.zero,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? opt.color.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(7) : Radius.zero,
                  bottom: isLast ? const Radius.circular(7) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Icon(opt.icon,
                      size: 20,
                      color: isSelected ? opt.color : AppTheme.outline),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? opt.color : AppTheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            key: const ValueKey('check'),
                            size: 20,
                            color: opt.color)
                        : Icon(Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('uncheck'),
                            size: 20,
                            color: AppTheme.outlineVariant),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
