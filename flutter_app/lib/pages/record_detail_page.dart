import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records.dart';
import '../config.dart';
import 'record_form_page.dart';

class RecordDetailPage extends StatefulWidget {
  final int recordId;
  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  bool _loading = false;
  bool _deleted = false;

  dynamic get record {
    final records = context.read<RecordsProvider>().records;
    return records.where((r) => r.id == widget.recordId).firstOrNull;
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条退货记录吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(Config.dangerColor)),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    final ok = await context.read<RecordsProvider>().deleteRecord(widget.recordId);
    setState(() => _loading = false);
    if (ok && mounted) {
      setState(() => _deleted = true);
      Navigator.pop(context, true);
    } else if (mounted) {
      final err = context.read<RecordsProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? '删除失败'), backgroundColor: const Color(Config.dangerColor)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (ctx, provider, _) {
        final rec = provider.records.where((r) => r.id == widget.recordId).firstOrNull;
        if (rec == null || _deleted) {
          return Scaffold(
            appBar: AppBar(title: const Text('记录详情')),
            body: const Center(child: Text('记录不存在或已删除')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('记录详情'),
            centerTitle: true,
            actions: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordFormPage(editId: widget.recordId),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(Config.dangerColor)),
                  tooltip: '删除',
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 状态 & 重点 标签
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(rec.status as String).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(rec.status as String),
                      style: TextStyle(
                        fontSize: 13,
                        color: _statusColor(rec.status as String),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (rec.isImportant == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(Config.warningColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '★ 重点',
                        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '¥${rec.refundAmount ?? 0}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(Config.dangerColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 信息卡片
              _infoCard(rec),
              const SizedBox(height: 12),

              // 原因卡片
              _reasonCard(rec),
              const SizedBox(height: 12),

              // 操作记录
              _logCard(rec),
              const SizedBox(height: 80),
            ],
          ),
          // 快捷操作按钮
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(Config.borderColor))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newStatus = rec.status == 'completed' ? 'pending' : 'completed';
                        final ok = await provider.updateRecord(rec.id, {'status': newStatus});
                        if (ok) setState(() {});
                      },
                      icon: Icon(
                        rec.status == 'completed' ? Icons.replay : Icons.check_circle_outline,
                        color: const Color(Config.successColor),
                      ),
                      label: Text(
                        rec.status == 'completed' ? '重置待处理' : '标记完成',
                        style: const TextStyle(color: Color(Config.successColor)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(Config.successColor)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordFormPage(editId: widget.recordId),
                          ),
                        );
                        if (result == true && mounted) setState(() {});
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('编辑', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(Config.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(dynamic rec) {
    return _Card(
      children: [
        _row('订单号', rec.orderNo ?? '-'),
        _divider(),
        _row('客户姓名', rec.customerName ?? '-'),
        _divider(),
        _row('联系电话', rec.customerPhone ?? '-'),
        _divider(),
        _row('商品名称', rec.productName ?? '-'),
        _divider(),
        _row('数量', '${rec.quantity ?? 1} 件'),
        _divider(),
        _row('退货日期', rec.returnDate != null ? rec.returnDate.toString().split(' ')[0] : '-'),
        _divider(),
        _row('录入人', rec.creatorName ?? '-'),
        _divider(),
        _row('录入时间', rec.createdAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(rec.createdAt))
            : '-'),
      ],
    );
  }

  Widget _reasonCard(dynamic rec) {
    return _Card(
      children: [
        _row('原因类型', rec.reasonType ?? '-'),
        _divider(),
        _row('详细原因', rec.refundReason ?? '-', isMulti: true),
        if (rec.remark != null && rec.remark.isNotEmpty) ...[
          _divider(),
          _row('备注', rec.remark, isMulti: true),
        ],
      ],
    );
  }

  Widget _logCard(dynamic rec) {
    return _Card(
      children: [
        _row('更新时间', rec.updatedAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(rec.updatedAt))
            : '-'),
        if (rec.handlerName != null && rec.handlerName.isNotEmpty) ...[
          _divider(),
          _row('处理人', rec.handlerName),
          _divider(),
          _row('处理时间', rec.handlerTime != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(rec.handlerTime))
              : '-'),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {bool isMulti = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMulti ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(Config.textSecondary)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(Config.textColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(Config.successColor);
      case 'processing':
        return const Color(Config.primaryColor);
      default:
        return const Color(Config.dangerColor);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'processing':
        return '处理中';
      default:
        return '待处理';
    }
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(Config.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(children: children),
    );
  }
}
