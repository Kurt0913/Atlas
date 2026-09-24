import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/invoice_service.dart';

class InvoiceExportDialog extends StatefulWidget {
  const InvoiceExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const InvoiceExportDialog(),
    );
  }

  @override
  State<InvoiceExportDialog> createState() => _InvoiceExportDialogState();
}

class _InvoiceExportDialogState extends State<InvoiceExportDialog> {
  late DateTime _from;
  late DateTime _to;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      await InvoiceService.instance.exportInvoicePdf(
        dateFrom: _from,
        dateTo: _to,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _exporting = false;
          _error = 'Export failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('MMM d, yyyy');

    return AlertDialog(
      actionsOverflowButtonSpacing: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF141F18) : Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF143D2B),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Export Invoice',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a date range. All completed tasks within the range will be included, grouped by currency.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF8EA397)
                      : const Color(0xFF5A6E64),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: 'From',
                      date: dateFmt.format(_from),
                      onTap: _exporting ? null : _pickFrom,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DatePickerTile(
                      label: 'To',
                      date: dateFmt.format(_to),
                      onTap: _exporting ? null : _pickTo,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF8EA397)
                  : const Color(0xFF5A6E64),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exporting ? null : _export,
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download_outlined, size: 18),
          label: Text(_exporting ? 'Generating…' : 'Export PDF'),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback? onTap;
  final bool isDark;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF0F5F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFF5A6E64),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: isDark
                      ? const Color(0xFFC88A32)
                      : const Color(0xFFB4782A),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFEDF5F0)
                          : const Color(0xFF0F1914),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
