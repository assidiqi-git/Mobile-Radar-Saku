import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_category.dart';
import '../../models/wallet.dart';
import '../../providers/sync_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedAction = AppConstants.actionDeduction; // default: expense
  WalletModel? _selectedWallet;
  TransactionCategoryModel? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWallet == null) {
      _showError('Pilih dompet terlebih dahulu');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Pilih kategori terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final txProvider = context.read<TransactionProvider>();
      final syncProvider = context.read<SyncProvider>();

      await txProvider.addTransaction(
        walletId: _selectedWallet!.id,
        transactionCategoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        amount: CurrencyFormatter.parse(_amountController.text),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      syncProvider.incrementPending();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan')),
      );
    } catch (e) {
      _showError('Gagal menyimpan transaksi');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector (Income / Expense / Neutral)
              _buildTypeSelector(),
              const SizedBox(height: 24),
              // Amount Field
              _buildAmountField(),
              const SizedBox(height: 20),
              // Transaction Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // Wallet Dropdown
              _buildWalletDropdown(),
              const SizedBox(height: 16),
              // Category Dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              // Note Field (optional)
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              // Save button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TypeChip(
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            selected: _selectedAction == AppConstants.actionDeduction,
            color: AppTheme.expenseColor,
            onTap: () {
              setState(() {
                _selectedAction = AppConstants.actionDeduction;
                _selectedCategory = null;
              });
            },
          ),
          _TypeChip(
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            selected: _selectedAction == AppConstants.actionAddition,
            color: AppTheme.incomeColor,
            onTap: () {
              setState(() {
                _selectedAction = AppConstants.actionAddition;
                _selectedCategory = null;
              });
            },
          ),
          _TypeChip(
            label: 'Netral',
            icon: Icons.remove_rounded,
            selected: _selectedAction == AppConstants.actionNeutral,
            color: AppTheme.secondary,
            onTap: () {
              setState(() {
                _selectedAction = AppConstants.actionNeutral;
                _selectedCategory = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTheme.monoStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _selectedAction == AppConstants.actionDeduction
            ? AppTheme.expenseColor
            : _selectedAction == AppConstants.actionAddition
                ? AppTheme.incomeColor
                : AppTheme.secondary,
      ),
      decoration: InputDecoration(
        prefixText: 'Rp ',
        prefixStyle: AppTheme.monoStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppTheme.outline,
        ),
        hintText: '0',
        hintStyle: AppTheme.monoStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: AppTheme.outlineVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
        final amount = CurrencyFormatter.parse(v);
        if (amount <= 0) return 'Jumlah harus lebih dari 0';
        return null;
      },
    );
  }

  Widget _buildWalletDropdown() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final wallets = walletProvider.wallets;
        return DropdownButtonFormField<WalletModel>(
          value: _selectedWallet,
          decoration: const InputDecoration(
            labelText: 'Dompet',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          isExpanded: true,
          hint: const Text('Pilih dompet'),
          items: wallets
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Row(
                    children: [
                      Text(w.name),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.compact(w.balance),
                        style: AppTheme.monoStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (w) => setState(() => _selectedWallet = w),
          validator: (v) => v == null ? 'Pilih dompet' : null,
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final categories = txProvider.getCategoriesByAction(_selectedAction);
        return DropdownButtonFormField<TransactionCategoryModel>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Kategori',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          isExpanded: true,
          hint: const Text('Pilih kategori'),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name),
                ),
              )
              .toList(),
          onChanged: (c) => setState(() => _selectedCategory = c),
          validator: (v) => v == null ? 'Pilih kategori' : null,
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: color.withOpacity(0.4))
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppTheme.outline, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: selected ? color : AppTheme.outline,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
