import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _noteController = TextEditingController();

  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  DateTime _transferDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppTheme.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _transferDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromWallet == null || _toWallet == null) {
      _showError('Pilih dompet asal dan tujuan');
      return;
    }
    if (_fromWallet!.id == _toWallet!.id) {
      _showError('Dompet asal dan tujuan tidak boleh sama');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amount = CurrencyFormatter.parse(_amountController.text);
      final fee = CurrencyFormatter.parse(_feeController.text);

      // Offline-first: saves locally + mutates balances + fires bg API call
      await context.read<WalletProvider>().doTransfer(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
        fee: fee,
        transferDate: DateFormatter.toApiString(_transferDate),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      // Form closes immediately — balance already updated in-memory
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer berhasil disimpan!')),
      );
    } catch (e) {
      _showError('Gagal menyimpan transfer. Coba lagi.');
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
      appBar: AppBar(title: const Text('Transfer Dana')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.secondary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt_outlined,
                        color: AppTheme.secondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Transfer disimpan secara lokal dan disinkronkan ke server di latar belakang.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wallet selector row
              _buildWalletSelector(),
              const SizedBox(height: 20),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                style: AppTheme.monoStyle(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'Jumlah Transfer',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final amount = CurrencyFormatter.parse(v);
                  if (amount < 1) {
                    return 'Jumlah minimal Rp1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                style: AppTheme.monoStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Biaya Transfer (opsional)',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final fee = CurrencyFormatter.parse(v);
                  if (fee < 0) return 'Biaya tidak boleh negatif';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Transfer date
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Transfer',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      suffixIcon: const Icon(Icons.chevron_right_rounded),
                    ),
                    controller: TextEditingController(
                      text: DateFormatter.displayDate(_transferDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: const Text('Proses Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final wallets = walletProvider.wallets;
        return Column(
          children: [
            DropdownButtonFormField<WalletModel>(
              value: _fromWallet,
              decoration: const InputDecoration(
                labelText: 'Dari Dompet',
                prefixIcon: Icon(Icons.arrow_upward_rounded, color: AppTheme.expenseColor),
              ),
              isExpanded: true,
              hint: const Text('Pilih dompet asal'),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Row(
                          children: [
                            Text(w.name),
                            const Spacer(),
                            Text(
                              CurrencyFormatter.compact(w.balance),
                              style: AppTheme.monoStyle(fontSize: 12, color: AppTheme.outline),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (w) => setState(() => _fromWallet = w),
              validator: (v) => v == null ? 'Pilih dompet asal' : null,
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<WalletModel>(
              value: _toWallet,
              decoration: const InputDecoration(
                labelText: 'Ke Dompet',
                prefixIcon: Icon(Icons.arrow_downward_rounded, color: AppTheme.incomeColor),
              ),
              isExpanded: true,
              hint: const Text('Pilih dompet tujuan'),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(w.name),
                      ))
                  .toList(),
              onChanged: (w) => setState(() => _toWallet = w),
              validator: (v) => v == null ? 'Pilih dompet tujuan' : null,
            ),
          ],
        );
      },
    );
  }
}
