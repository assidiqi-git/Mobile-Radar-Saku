import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Dompet Saya')),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final wallets = provider.wallets;
          return Column(
            children: [
              // Total balance
              _buildTotalCard(provider.totalBalance),
              // Wallet list
              Expanded(
                child: wallets.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: wallets.length,
                        itemBuilder: (_, i) =>
                            _WalletTile(wallet: wallets[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Dompet'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryContainer, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Semua Dompet',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(total),
                style: AppTheme.monoStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white30,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.outline,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada dompet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan dompet pertama Anda',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWalletSheet(),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final WalletModel wallet;

  const _WalletTile({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(wallet.type),
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.typeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(wallet.balance),
                style: AppTheme.monoStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showEditSheet(context, wallet),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, wallet),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'checking':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }

  void _showEditSheet(BuildContext context, WalletModel wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWalletSheet(walletToEdit: wallet),
    );
  }

  void _confirmDelete(BuildContext context, WalletModel wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet'),
        content: Text(
          'Apakah Anda yakin ingin menghapus dompet "${wallet.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WalletProvider>().deleteWallet(wallet.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _AddWalletSheet extends StatefulWidget {
  final WalletModel? walletToEdit;
  const _AddWalletSheet({this.walletToEdit});

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'cash';
  bool _isLoading = false;

  bool get isEdit => widget.walletToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = widget.walletToEdit!.name;
      _balanceController.text = widget.walletToEdit!.balance;
      _selectedType = widget.walletToEdit!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<WalletProvider>();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    if (isEdit) {
      await provider.updateWallet(
        widget.walletToEdit!.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: balance,
      );
    } else {
      await provider.createWallet(
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: balance,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEdit ? 'Edit Dompet' : 'Tambah Dompet',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Dompet',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Dompet',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.walletTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeLabel(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTheme.monoStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Dompet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'checking':
        return 'Giro';
      case 'savings':
        return 'Tabungan';
      case 'cash':
        return 'Tunai';
      case 'investment':
        return 'Investasi';
      default:
        return type;
    }
  }
}
