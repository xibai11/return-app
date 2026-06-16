import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records.dart';
import '../config.dart';
import 'record_form_page.dart';
import 'record_detail_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortOrder = 'newest';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('退货记录'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecordsProvider>().load(refresh: true),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '排序与筛选',
            onSelected: (v) {
              if (v.startsWith('sort_')) {
                setState(() => _sortOrder = v.substring(5));
              } else if (v.startsWith('filter_')) {
                setState(() => _statusFilter = v.substring(7));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sort_newest', child: Text('按时间最新')),
              const PopupMenuItem(value: 'sort_oldest', child: Text('按时间最旧')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'filter_all', child: Text('全部状态')),
              const PopupMenuItem(value: 'filter_pending', child: Text('仅待处理')),
              const PopupMenuItem(value: 'filter_completed', child: Text('仅已完成')),
              const PopupMenuItem(value: 'filter_important', child: Text('仅重点')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: '搜索单号/客户/商品...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(Config.bgColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: Consumer<RecordsProvider>(
              builder: (ctx, provider, _) {
                if (provider.loading && provider.records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                var records = provider.records as List;

                // 筛选
                if (_statusFilter != 'all') {
                  records = records.where((r) {
                    final s = r.status as String;
                    if (_statusFilter == 'pending') return s == 'pending';
                    if (_statusFilter == 'completed') return s == 'completed';
                    if (_statusFilter == 'important') return r.isImportant == true;
                    return true;
                  }).toList();
                }

                // 搜索
                if (_searchQuery.isNotEmpty) {
                  records = records.where((r) {
                    final q = _searchQuery;
                    return (r.orderNo?.toLowerCase().contains(q) ?? false) ||
                        (r.customerName?.toLowerCase().contains(q) ?? false) ||
                        (r.productName?.toLowerCase().contains(q) ?? false) ||
                        (r.creatorName?.toLowerCase().contains(q) ?? false);
                  }).toList();
                }

                // 排序
                records.sort((a, b) {
                  final diff = DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt));
                  return _sortOrder == 'newest' ? -diff : diff;
                });

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? '未找到匹配记录' : '暂无记录',
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: records.length,
                    itemBuilder: (ctx, i) {
                      final record = records[i];
                      return _RecordCard(
                        record: record,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailPage(recordId: record.id),
                            ),
                          );
                          if (result == true && mounted) {
                            provider.load(refresh: true);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordFormPage()),
          );
          if (result == true && mounted) {
            context.read<RecordsProvider>().load(refresh: true);
          }
        },
        backgroundColor: const Color(Config.primaryColor),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final dynamic record;
  final VoidCallback onTap;

  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status as String);
    final statusLabel = _statusLabel(record.status as String);
    final isImportant = record.isImportant == true;
    final createdAt = DateTime.parse(record.createdAt as String);
    final dateStr = DateFormat('MM-dd HH:mm').format(createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isImportant ? const Color(Config.warningColor).withOpacity(0.5) : const Color(Config.borderColor),
            width: isImportant ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isImportant)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(Config.warningColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '★ 重点',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: Color(Config.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.receipt_outlined, size: 16, color: Color(Config.textSecondary)),
                const SizedBox(width: 4),
                Text(
                  record.orderNo ?? '-',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(Config.textColor)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(Config.textSecondary)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.customerName ?? '-',
                    style: const TextStyle(fontSize: 13, color: Color(Config.textSecondary)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.inventory_2_outlined, size: 16, color: Color(Config.textSecondary)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.productName ?? '-',
                    style: const TextStyle(fontSize: 13, color: Color(Config.textSecondary)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 16, color: Color(Config.textSecondary)),
                const SizedBox(width: 4),
                Text(
                  record.creatorName ?? '-',
                  style: const TextStyle(fontSize: 12, color: Color(Config.textSecondary)),
                ),
                const Spacer(),
                Text(
                  '¥${record.refundAmount ?? 0}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(Config.dangerColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
