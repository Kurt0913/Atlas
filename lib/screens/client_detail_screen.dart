import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../models/task_item.dart';
import '../providers/client_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<TaskItem> _clientTasks = [];
  bool _isLoadingTasks = true;

  @override
  void initState() {
    super.initState();
    _loadClientTasks();
  }

  Future<void> _loadClientTasks() async {
    setState(() => _isLoadingTasks = true);
    final tasks = await context.read<TaskProvider>().getClientTasks(widget.clientId);
    if (mounted) {
      setState(() {
        _clientTasks = tasks;
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _handleContactPress(Client client) async {
    if (client.contactMethod.isEmpty) return;

    var url = client.contactMethod.trim();
    if (url.startsWith('m.me/')) {
      url = 'https://$url';
    } else if (url.startsWith('wa.me/')) {
      url = 'https://$url';
    } else if (url.startsWith('t.me/') || url.startsWith('telegram.me/')) {
      url = 'https://$url';
    } else if (url.contains('@') && !url.contains('/')) {
      url = 'mailto:$url';
    } else if (!url.contains('://')) {
      if (client.contactType == 'Phone' || client.contactType == 'WhatsApp') {
        url = 'tel:$url';
      } else {
        url = 'https://$url';
      }
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open contact method.')),
          );
        }
      }
    }
  }

  String? _calculateTimezoneTime(String timezone) {
    try {
      // Basic formatting fallback
      final now = DateTime.now().toUtc();
      if (timezone == 'Asia/Manila') {
        final pht = now.add(const Duration(hours: 8));
        return DateFormat('h:mm a').format(pht);
      } else if (timezone == 'America/New_York') {
        final est = now.subtract(const Duration(hours: 4)); // approx EDT
        return DateFormat('h:mm a').format(est);
      } else if (timezone == 'America/Los_Angeles') {
        final pst = now.subtract(const Duration(hours: 7)); // approx PDT
        return DateFormat('h:mm a').format(pst);
      } else if (timezone == 'Europe/London') {
        final gmt = now.add(const Duration(hours: 1)); // approx BST
        return DateFormat('h:mm a').format(gmt);
      }
      return DateFormat('h:mm a').format(DateTime.now());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0.##');

    final client = clientProvider.clients.cast<Client?>().firstWhere(
          (c) => c?.id == widget.clientId,
          orElse: () => null,
        );

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Details')),
        body: const Center(child: Text('Client not found.')),
      );
    }

    final localTime = _calculateTimezoneTime(client.timezone);
    final showEarnings = client.rateType.isEmpty ||
        client.rateType == 'Per Task' ||
        client.rateType == 'Fixed Project';
    final monthlyTotal = _clientTasks
        .where((t) => t.status == 'done')
        .fold<double>(0.0, (sum, _) => sum + client.rate);

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await ClientFormDialog.show(context, initialClient: client);
              _loadClientTasks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await clientProvider.loadClients();
          await _loadClientTasks();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFFF2DF)
                                  : const Color(0xFF5F452B),
                            ),
                          ),
                        ),
                        if (localTime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFFD9C3A8)
                                    : const Color(0xFF8B6D4C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localTime,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFD9C3A8)
                                      : const Color(0xFF8B6D4C),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      client.platform.isNotEmpty ? client.platform : 'Direct',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFD9C3A8)
                            : const Color(0xFF8B6D4C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${client.currency} ${formatter.format(client.rate)} / ${client.rateSuffix}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (client.contactMethod.isNotEmpty)
                      InkWell(
                        onTap: () => _handleContactPress(client),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                client.contactType == 'Email'
                                    ? Icons.email_outlined
                                    : (client.contactType == 'Phone' ||
                                            client.contactType == 'WhatsApp')
                                        ? Icons.phone_outlined
                                        : Icons.chat_bubble_outline,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFFF6AD55)
                                    : const Color(0xFFB7791F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                client.contactType != 'Other'
                                    ? '${client.contactType}: ${client.contactMethod}'
                                    : client.contactMethod,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFF6AD55)
                                      : const Color(0xFFB7791F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'No contact method set',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFD9C3A8)
                              : const Color(0xFF8B6D4C),
                        ),
                      ),
                    if (client.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        client.notes,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFEBE1D5)
                              : const Color(0xFF241E15),
                        ),
                      ),
                    ],
                    if (showEarnings) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${client.currency} ${formatter.format(monthlyTotal)} earned this month',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskFormScreen(
                            preselectedClientId: client.id,
                          ),
                        ),
                      ).then((_) => _loadClientTasks());
                    },
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Add Task'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteClient(context, client),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Tasks (${_clientTasks.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFFFF2DF)
                    : const Color(0xFF5F452B),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoadingTasks)
              const Center(child: CircularProgressIndicator())
            else if (_clientTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.content_paste_outlined,
                      size: 48,
                      color: isDark
                          ? const Color(0xFF5F4A36)
                          : const Color(0xFFECD8B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks found for this client.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFD9C3A8)
                            : const Color(0xFF8B6D4C),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._clientTasks.map((task) => TaskCard(
                    task: task,
                    onStatusChange: (status) async {
                      await taskProvider.updateTaskStatus(task.id!, status);
                      _loadClientTasks();
                    },
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskFormScreen(existingTask: task),
                        ),
                      ).then((_) => _loadClientTasks());
                    },
                    onDelete: () async {
                      await taskProvider.deleteTask(task.id!);
                      _loadClientTasks();
                    },
                  )),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${client.name}? All of their tasks will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<ClientProvider>().deleteClient(client.id!);
              await context.read<TaskProvider>().loadAll();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
