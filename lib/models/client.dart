class Client {
  final int? id;
  final String name;
  final String platform;
  final double rate;
  final String rateType;
  final String currency;
  final String contactType;
  final String contactMethod;
  final String timezone;
  final String notes;
  final int activeTasks;

  const Client({
    this.id,
    required this.name,
    this.platform = 'Direct',
    this.rate = 0.0,
    this.rateType = 'Per Task',
    this.currency = 'PHP',
    this.contactType = 'Other',
    this.contactMethod = '',
    this.timezone = 'UTC',
    this.notes = '',
    this.activeTasks = 0,
  });

  Client copyWith({
    int? id,
    String? name,
    String? platform,
    double? rate,
    String? rateType,
    String? currency,
    String? contactType,
    String? contactMethod,
    String? timezone,
    String? notes,
    int? activeTasks,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      rate: rate ?? this.rate,
      rateType: rateType ?? this.rateType,
      currency: currency ?? this.currency,
      contactType: contactType ?? this.contactType,
      contactMethod: contactMethod ?? this.contactMethod,
      timezone: timezone ?? this.timezone,
      notes: notes ?? this.notes,
      activeTasks: activeTasks ?? this.activeTasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'platform': platform,
      'rate': rate,
      'rate_type': rateType,
      'currency': currency,
      'contact_type': contactType,
      'contact_method': contactMethod,
      'timezone': timezone,
      'notes': notes,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      platform: map['platform'] as String? ?? 'Direct',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      rateType: map['rate_type'] as String? ?? 'Per Task',
      currency: map['currency'] as String? ?? 'PHP',
      contactType: map['contact_type'] as String? ?? 'Other',
      contactMethod: map['contact_method'] as String? ?? '',
      timezone: map['timezone'] as String? ?? 'UTC',
      notes: map['notes'] as String? ?? '',
      activeTasks: (map['active_tasks'] as num?)?.toInt() ?? 0,
    );
  }

  String get rateSuffix {
    switch (rateType) {
      case 'Per Task':
        return 'Task';
      case 'Hourly':
        return 'Hr';
      case 'Fixed Project':
        return 'Project';
      case 'Monthly':
        return 'Mo';
      default:
        return 'Task';
    }
  }
}
