import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../utils/date_helpers.dart';

class ClientCard extends StatefulWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
  });

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  late Timer _timer;
  late String _localTime;
  late int _localHour;

  @override
  void initState() {
    super.initState();
    _refreshTime();
    // Refresh every 30 seconds so the time stays live
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refreshTime();
    });
  }

  void _refreshTime() {
    setState(() {
      _localTime = DateHelpers.clientLocalTimeString(widget.client.timezone);
      _localHour = DateHelpers.clientLocalHour(widget.client.timezone);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Returns true if the client is likely awake (6 AM – 10 PM local).
  bool get _isAwakeHour => _localHour >= 6 && _localHour < 22;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0.##');
    final tzLabel = DateHelpers.clientTimezoneLabel(widget.client.timezone);
    final hasTimezone =
        widget.client.timezone.isNotEmpty && widget.client.timezone != 'UTC';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141F18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name row + local time pill ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.client.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFEDF5F0)
                              : const Color(0xFF0F1914),
                        ),
                      ),
                    ),
                    if (_localTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _LocalTimePill(
                        time: _localTime,
                        tzLabel: tzLabel,
                        isAwake: _isAwakeHour,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // ── Platform + rate row ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.client.platform.isNotEmpty
                                ? widget.client.platform
                                : 'Direct',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFEDF5F0)
                                  : const Color(0xFF0F1914),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.client.currency} ${formatter.format(widget.client.rate)} / ${widget.client.rateSuffix}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFEDF5F0)
                              : const Color(0xFF0F1914),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Active tasks + timezone ───────────────────────────
                Row(
                  children: [
                    Text(
                      '${widget.client.activeTasks} active task${widget.client.activeTasks == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8EA397)
                            : const Color(0xFF5A6E64),
                      ),
                    ),
                    if (hasTimezone) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF8EA397)
                              : const Color(0xFF8C9E95),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.language_outlined,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF8EA397)
                            : const Color(0xFF5A6E64),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        tzLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF8EA397)
                              : const Color(0xFF5A6E64),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? get onTap => widget.onTap;
}

/// A live pill showing the client's local time with a breathing pulse dot
/// when they are in active working hours, and a gentle crescent moon when asleep.
class _LocalTimePill extends StatefulWidget {
  final String time;
  final String tzLabel;
  final bool isAwake;
  final bool isDark;

  const _LocalTimePill({
    required this.time,
    required this.tzLabel,
    required this.isAwake,
    required this.isDark,
  });

  @override
  State<_LocalTimePill> createState() => _LocalTimePillState();
}

class _LocalTimePillState extends State<_LocalTimePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isAwake = widget.isAwake;
    const awakeColor = Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2C23) : const Color(0xFFF0F5F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF263B2F) : const Color(0xFFDDE6E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAwake)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 6 + (5 * _pulseAnimation.value),
                      height: 6 + (5 * _pulseAnimation.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: awakeColor.withValues(
                          alpha: 0.35 * (1.0 - _pulseAnimation.value),
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: awakeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: awakeColor.withValues(alpha: 0.4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          else
            const Text(
              '☾',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                height: 1.0,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            widget.time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFEDF5F0) : const Color(0xFF0F1914),
            ),
          ),
          if (!isAwake) ...[
            const SizedBox(width: 4),
            Text(
              'asleep',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? const Color(0xFF8EA397)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
