import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileInfoSection extends StatelessWidget {
  final User user;

  const ProfileInfoSection({
    required this.user,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Informationen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Name',
              value: user.displayName ?? 'Nicht angegeben',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.email,
              label: 'E-Mail',
              value: user.email ?? 'Nicht angegeben',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.verified_user,
              label: 'E-Mail verifiziert',
              value: user.emailVerified ? 'Ja' : 'Nein',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Erstellt am',
              value: user.metadata.creationTime != null
                  ? _formatDate(user.metadata.creationTime!)
                  : 'Unbekannt',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.login,
              label: 'Letzte Anmeldung',
              value: user.metadata.lastSignInTime != null
                  ? _formatDate(user.metadata.lastSignInTime!)
                  : 'Unbekannt',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
