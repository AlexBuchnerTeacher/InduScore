import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import 'package:intl/intl.dart';

/// Readonly User-Info Section für Profil-Tab
/// 
/// Zeigt alle Benutzerdaten in übersichtlichen Karten an:
/// - Benutzerdaten (Kürzel, E-Mail, Name, Rolle, Status)
/// - Account-Informationen (Erstellt am, Letzter Login)
/// 
/// Alle Felder sind schreibgeschützt. Bearbeitung über Admin-Settings.
class ProfileInfoSection extends StatelessWidget {
  /// Der anzuzeigende Benutzer
  final AppUser user;

  const ProfileInfoSection({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RBSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RBSHeadline(
                text: 'Benutzerdaten',
                level: RBSHeadlineLevel.h3,
              ),
              const SizedBox(height: RBSSpacing.md),
              _buildInfoRow('Kürzel', user.kuerzel),
              const Divider(height: RBSSpacing.lg),
              _buildInfoRow('E-Mail', user.email),
              const Divider(height: RBSSpacing.lg),
              _buildInfoRow('Name', user.name),
              const Divider(height: RBSSpacing.lg),
              _buildInfoRow('Rolle', user.rolle.label),
              const Divider(height: RBSSpacing.lg),
              _buildInfoRow(
                'Status',
                user.status.label,
                valueColor: user.status == UserStatus.aktiv
                    ? RBSColors.success
                    : RBSColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: RBSSpacing.md),
        RBSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RBSHeadline(
                text: 'Account-Informationen',
                level: RBSHeadlineLevel.h3,
              ),
              const SizedBox(height: RBSSpacing.md),
              _buildInfoRow('Erstellt am', dateFormat.format(user.createdAt)),
              if (user.lastLoginAt != null) ...[
                const Divider(height: RBSSpacing.lg),
                _buildInfoRow(
                  'Letzter Login',
                  dateFormat.format(user.lastLoginAt!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: RBSSpacing.lg),
        const RBSButton(
          label: 'Profil bearbeiten',
          onPressed: null, // Disabled
          icon: Icons.edit_outlined,
        ),
        const SizedBox(height: RBSSpacing.sm),
        const Text(
          'Profil-Bearbeitung demnächst verfügbar',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 13,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: RBSSpacing.md),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? RBSColors.textOnLight,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
