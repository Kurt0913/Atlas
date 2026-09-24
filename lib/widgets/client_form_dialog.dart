import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../providers/preferences_provider.dart';

class ClientFormDialog extends StatefulWidget {
  final Client? initialClient;

  const ClientFormDialog({super.key, this.initialClient});

  static Future<void> show(BuildContext context, {Client? initialClient}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ClientFormDialog(initialClient: initialClient),
    );
  }

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  static const List<String> platformPresets = [
    'Upwork',
    'Onlinejobs',
    'Fiverr',
    'Direct',
    'Facebook',
    'LinkedIn',
    'Other'
  ];

  static const List<String> currencyPresets = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'AUD',
    'CAD'
  ];

  static const List<String> rateTypePresets = [
    'Per Task',
    'Hourly',
    'Fixed Project',
    'Monthly'
  ];

  static const List<String> contactTypePresets = [
    'Messenger',
    'Telegram',
    'WhatsApp',
    'Email',
    'Phone',
    'LinkedIn',
    'Other'
  ];

  static const List<Map<String, String>> timezonePresets = [
    {'label': 'UTC', 'value': 'UTC'},
    {'label': 'PHT (Manila)', 'value': 'Asia/Manila'},
    {'label': 'EST (New York)', 'value': 'America/New_York'},
    {'label': 'PST (Los Angeles)', 'value': 'America/Los_Angeles'},
    {'label': 'CST (Chicago)', 'value': 'America/Chicago'},
    {'label': 'GMT (London)', 'value': 'Europe/London'},
    {'label': 'AEST (Sydney)', 'value': 'Australia/Sydney'},
    {'label': 'CEST (Europe)', 'value': 'Europe/Berlin'},
    {'label': 'IST (India)', 'value': 'Asia/Kolkata'},
  ];

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _contactMethodController;
  late TextEditingController _notesController;

  late String _platform;
  late String _rateType;
  late String _currency;
  late String _contactType;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    final client = widget.initialClient;
    final defaultCurrency =
        context.read<PreferencesProvider>().defaultCurrency;

    _nameController = TextEditingController(text: client?.name ?? '');
    _rateController = TextEditingController(
        text: client != null && client.rate > 0 ? client.rate.toString() : '');
    _contactMethodController =
        TextEditingController(text: client?.contactMethod ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');

    _platform = client?.platform ?? 'Direct';
    _rateType = client?.rateType ?? 'Per Task';
    _currency = client?.currency ?? defaultCurrency;
    _contactType = client?.contactType ?? 'Email';
    _timezone = client?.timezone ?? 'UTC';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _contactMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getContactPlaceholder() {
    switch (_contactType) {
      case 'Messenger':
        return 'm.me/...';
      case 'Email':
        return 'email@domain.com';
      case 'Phone':
      case 'WhatsApp':
        return '+1...';
      case 'Telegram':
        return 't.me/...';
      default:
        return 'Handle or URL';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final rateVal = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final clientProvider = context.read<ClientProvider>();

    if (widget.initialClient != null) {
      final updated = widget.initialClient!.copyWith(
        name: _nameController.text.trim(),
        platform: _platform,
        rate: rateVal,
        rateType: _rateType,
        currency: _currency,
        contactType: _contactType,
        contactMethod: _contactMethodController.text.trim(),
        timezone: _timezone,
        notes: _notesController.text.trim(),
      );
      await clientProvider.updateClient(updated);
    } else {
      final newClient = Client(
        name: _nameController.text.trim(),
        platform: _platform,
        rate: rateVal,
        rateType: _rateType,
        currency: _currency,
        contactType: _contactType,
        contactMethod: _contactMethodController.text.trim(),
        timezone: _timezone,
        notes: _notesController.text.trim(),
      );
      await clientProvider.addClient(newClient);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        widget.initialClient != null ? 'Edit Client' : 'New Client',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFFFF2DF) : const Color(0xFF5F452B),
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    hintText: 'e.g. Acme Corp',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Client name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _platform,
                        decoration: const InputDecoration(labelText: 'Platform'),
                        items: platformPresets
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _platform = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _timezone,
                        decoration: const InputDecoration(labelText: 'Timezone'),
                        items: timezonePresets
                            .map((tz) => DropdownMenuItem(
                                  value: tz['value'],
                                  child: Text(
                                    tz['label']!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _timezone = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _rateType,
                        decoration:
                            const InputDecoration(labelText: 'Rate Type'),
                        items: rateTypePresets
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _rateType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _currency,
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        items: currencyPresets
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _currency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Rate Amount',
                    prefixText: '$_currency ',
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final n = double.tryParse(val.trim());
                      if (n == null || n < 0) {
                        return 'Rate must be a positive number.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _contactType,
                        decoration:
                            const InputDecoration(labelText: 'Contact Type'),
                        items: contactTypePresets
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _contactType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _contactMethodController,
                        decoration: InputDecoration(
                          labelText: 'Contact Info',
                          hintText: _getContactPlaceholder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional client requirements or links',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? const Color(0xFFF6E2C7) : const Color(0xFF6B4D2C),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
