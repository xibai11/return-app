class User {
  final int id;
  final String username;
  final String name;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isAdmin => role == 'admin';
}

class Record {
  final int id;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final String productName;
  final int quantity;
  final double refundAmount;
  final String refundReason;
  final String reasonType;
  final String remark;
  final String returnDate;
  final bool isImportant;
  final String status; // pending / processing / completed
  final int createdById;
  final String creatorName;
  final int? handlerId;
  final String? handlerName;
  final String? handlerTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Record({
    required this.id,
    required this.orderNo,
    required this.customerName,
    this.customerPhone = '',
    this.productName = '',
    this.quantity = 1,
    this.refundAmount = 0,
    this.refundReason = '',
    this.reasonType = '',
    this.remark = '',
    this.returnDate = '',
    this.isImportant = false,
    this.status = 'pending',
    this.createdById = 0,
    this.creatorName = '',
    this.handlerId,
    this.handlerName,
    this.handlerTime,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] ?? 0,
      orderNo: json['order_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      refundAmount: (json['refund_amount'] ?? 0).toDouble(),
      refundReason: json['refund_reason'] ?? '',
      reasonType: json['reason_type'] ?? '',
      remark: json['remark'] ?? '',
      returnDate: json['return_date'] ?? '',
      isImportant: json['is_important'] == true || json['is_important'] == 1,
      status: json['status'] ?? 'pending',
      createdById: json['created_by_id'] ?? 0,
      creatorName: json['creator_name'] ?? '',
      handlerId: json['handler_id'],
      handlerName: json['handler_name'],
      handlerTime: json['handler_time'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_no': orderNo,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'product_name': productName,
      'quantity': quantity,
      'refund_amount': refundAmount,
      'refund_reason': refundReason,
      'reason_type': reasonType,
      'remark': remark,
      'return_date': returnDate,
      'is_important': isImportant ? 1 : 0,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
}

class DashboardStats {
  final int total;
  final int pending;
  final int completed;
  final int importantPending;
  final int todayNew;
  final int todayDone;
  final List<DayStat> trend;
  final List<UserStat> userStats;
  final List<ReasonStat> reasonStats;

  DashboardStats({
    required this.total,
    required this.pending,
    required this.completed,
    required this.importantPending,
    required this.todayNew,
    required this.todayDone,
    required this.trend,
    required this.userStats,
    required this.reasonStats,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      importantPending: json['important_pending'] ?? 0,
      todayNew: json['today_new'] ?? 0,
      todayDone: json['today_done'] ?? 0,
      trend: (json['trend'] as List? ?? [])
          .map((e) => DayStat.fromJson(e))
          .toList(),
      userStats: (json['user_stats'] as List? ?? [])
          .map((e) => UserStat.fromJson(e))
          .toList(),
      reasonStats: (json['reason_stats'] as List? ?? [])
          .map((e) => ReasonStat.fromJson(e))
          .toList(),
    );
  }
}

class DayStat {
  final String date;
  final int newCount;
  final int doneCount;

  DayStat({
    required this.date,
    required this.newCount,
    required this.doneCount,
  });

  factory DayStat.fromJson(Map<String, dynamic> json) {
    return DayStat(
      date: json['date'] ?? '',
      newCount: json['new_count'] ?? 0,
      doneCount: json['done_count'] ?? 0,
    );
  }
}

class UserStat {
  final String userName;
  final int count;

  UserStat({required this.userName, required this.count});

  factory UserStat.fromJson(Map<String, dynamic> json) {
    return UserStat(
      userName: json['user_name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ReasonStat {
  final String reason;
  final int count;

  ReasonStat({required this.reason, required this.count});

  factory ReasonStat.fromJson(Map<String, dynamic> json) {
    return ReasonStat(
      reason: json['reason'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
