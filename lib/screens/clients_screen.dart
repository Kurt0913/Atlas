import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/client_card.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/editorial_tip_card.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final clients = clientProvider.clients;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => clientProvider.loadClients(),
      color: AppTheme.brassAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (clients.isEmpty)
            // ── Centered, Balanced Empty State ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14241B)
                          : const Color(0xFFE8EFEA),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.groups_outlined,
                      size: 36,
                      color: isDark
                          ? const Color(0xFF8EA397)
                          : const Color(0xFF5A6E64),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No clients on your roster yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFEDF5F0)
                          : const Color(0xFF0F1914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add direct clients, platforms, and agencies to track rates, timezones, and earnings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFF8EA397)
                          : const Color(0xFF5A6E64),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ClientFormDialog.show(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add First Client'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // ── Top CTA Button when list is active ─────────────────────────
            ElevatedButton.icon(
              onPressed: () => ClientFormDialog.show(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Client'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...clients.map((client) => ClientCard(
                  client: client,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClientDetailScreen(clientId: client.id!),
                      ),
                    );
                  },
                )),
            // ── Distinct Editorial Guidance Card (Warm paper, dashed border, actionable) ─
            if (clients.length <= 2) ...[
              const SizedBox(height: 8),
              EditorialTipCard(
                eyebrow: 'Timezone Intelligence',
                title: 'Local time awareness',
                message:
                    'Set ${clients.first.name}\'s timezone to track when they are awake and get realistic deadline alerts.',
                actionLabel: 'Set now →',
                icon: Icons.schedule_outlined,
                onAction: () {
                  ClientFormDialog.show(context, initialClient: clients.first);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
