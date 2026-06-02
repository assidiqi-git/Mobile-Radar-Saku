import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../settings/transaction_category_list_screen.dart';
import '../settings/transaction_type_list_screen.dart';

class ProfileSyncScreen extends StatelessWidget {
  const ProfileSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Profil & Sinkronisasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 20),
            _buildSyncCard(context),
            const SizedBox(height: 20),
            _buildSettingsMenuCard(context),
            const SizedBox(height: 20),
            _buildAppInfoCard(),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Container(
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '-',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sync.hasPending
                          ? const Color(0xFFFEF3C7)
                          : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      sync.isSyncing
                          ? Icons.sync_rounded
                          : sync.hasPending
                              ? Icons.sync_problem_rounded
                              : Icons.check_circle_rounded,
                      color: sync.isSyncing
                          ? AppTheme.secondary
                          : sync.hasPending
                              ? const Color(0xFFD97706)
                              : AppTheme.incomeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinkronisasi',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        sync.isSyncing
                            ? 'Sedang menyinkron...'
                            : sync.hasPending
                                ? '${sync.pendingCount} transaksi pending'
                                : 'Semua data tersinkron',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Last synced info
              _buildInfoRow(
                label: 'Terakhir Disinkron',
                value: sync.lastSyncedAt != null
                    ? DateFormatter.displayFull(sync.lastSyncedAt)
                    : 'Belum pernah',
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                label: 'Transaksi Pending',
                value: sync.pendingCount.toString(),
                icon: Icons.pending_outlined,
              ),
              const SizedBox(height: 20),
              // Sync status info
              if (sync.status == SyncStatus.error && sync.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sync.errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              // Sync button
              ElevatedButton.icon(
                onPressed: sync.isSyncing
                    ? null
                    : () async {
                        await sync.sync();
                        if (context.mounted &&
                            sync.status == SyncStatus.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sinkronisasi berhasil!'),
                            ),
                          );
                        }
                      },
                icon: sync.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(
                    sync.isSyncing ? 'Menyinkron...' : 'Sinkron Sekarang'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.outline),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Pengaturan',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildMenuTile(
            context,
            icon: Icons.category_rounded,
            iconColor: AppTheme.secondary,
            iconBgColor: AppTheme.secondary.withOpacity(0.1),
            label: 'Manajemen Tipe Transaksi',
            subtitle: 'Pemasukan, pengeluaran, dll.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionTypeListScreen(),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuTile(
            context,
            icon: Icons.folder_special_rounded,
            iconColor: AppTheme.primary,
            iconBgColor: AppTheme.primary.withOpacity(0.1),
            label: 'Manajemen Kategori Transaksi',
            subtitle: 'Makan, belanja, gaji, dll.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionCategoryListScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.info_outline_rounded,
            label: 'Versi Aplikasi',
            value: '0.1.0',
          ),
          const Divider(height: 20),
          _buildSettingRow(
            icon: Icons.storage_rounded,
            label: 'Mode Penyimpanan',
            value: 'Offline-First (SQLite)',
          ),
          const Divider(height: 20),
          _buildSettingRow(
            icon: Icons.cloud_rounded,
            label: 'Status Server',
            value: 'Laravel REST API',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.outline),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.logout_rounded, color: AppTheme.expenseColor),
      label: Text(
        'Keluar',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.expenseColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.expenseColor),
        foregroundColor: AppTheme.expenseColor,
        minimumSize: const Size(double.infinity, 52),
        shape: const StadiumBorder(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Data lokal akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
