import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard.dart';
import '../config.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('退货登记系统'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().load(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (ctx, provider, _) {
          if (provider.loading && provider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = provider.stats;
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 统计卡片
                _StatGrid(stats: stats),
                const SizedBox(height: 16),
                // 近7天趋势图
                _TrendChart(stats: stats),
                const SizedBox(height: 16),
                // 退款原因 TOP
                if (stats != null && stats.reasonStats.isNotEmpty)
                  _ReasonList(stats: stats),
                if (stats != null && stats.userStats.isNotEmpty)
                  const SizedBox(height: 16),
                if (stats != null && stats.userStats.isNotEmpty)
                  _UserList(stats: stats),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final dynamic stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              title: '今日新增',
              value: '${stats?.todayNew ?? 0}',
              color: const Color(Config.primaryColor),
              icon: Icons.add_circle_outline,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              title: '今日完成',
              value: '${stats?.todayDone ?? 0}',
              color: const Color(Config.successColor),
              icon: Icons.check_circle_outline,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: '待处理',
              value: '${stats?.pending ?? 0}',
              color: const Color(Config.dangerColor),
              icon: Icons.pending_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              title: '重点待办',
              value: '${stats?.importantPending ?? 0}',
              color: const Color(Config.warningColor),
              icon: Icons.star_outline,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: '总记录数',
              value: '${stats?.total ?? 0}',
              color: const Color(Config.textColor),
              icon: Icons.analytics_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              title: '已完成',
              value: '${stats?.completed ?? 0}',
              color: const Color(Config.successColor),
              icon: Icons.task_alt_outlined,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(Config.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Color(Config.textSecondary),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final dynamic stats;
  const _TrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final trend = stats?.trend ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(Config.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '近 7 天趋势',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(Config.textColor),
            ),
          ),
          const SizedBox(height: 16),
          if (trend.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('暂无数据', style: TextStyle(color: Color(Config.textSecondary))),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(trend.length, (i) {
                  final stat = trend[i];
                  final maxNew = trend.map((e) => e.newCount as int).reduce((a, b) => a > b ? a : b);
                  final maxDone = trend.map((e) => e.doneCount as int).reduce((a, b) => a > b ? a : b);
                  final maxVal = maxNew > maxDone ? maxNew : maxDone;
                  final newH = maxVal > 0 ? (stat.newCount / maxVal * 120).roundToDouble() : 0.0;
                  final doneH = maxVal > 0 ? (stat.doneCount / maxVal * 120).roundToDouble() : 0.0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 14,
                              height: newH.clamp(2, 120),
                              decoration: BoxDecoration(
                                color: const Color(Config.primaryColor).withOpacity(0.8),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 14,
                              height: doneH.clamp(2, 120),
                              decoration: BoxDecoration(
                                color: const Color(Config.successColor).withOpacity(0.8),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stat.date,
                          style: const TextStyle(fontSize: 10, color: Color(Config.textSecondary)),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(Config.primaryColor), '新增'),
              const SizedBox(width: 20),
              _legend(const Color(Config.successColor), '完成'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(Config.textSecondary))),
      ],
    );
  }
}

class _ReasonList extends StatelessWidget {
  final dynamic stats;
  const _ReasonList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final reasons = stats.reasonStats as List;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(Config.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '退款原因分布（近30天）',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(Config.textColor)),
          ),
          const SizedBox(height: 12),
          ...reasons.take(5).map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    r.reason,
                    style: const TextStyle(color: Color(Config.textColor), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.count} 次',
                  style: const TextStyle(
                    color: Color(Config.primaryColor),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final dynamic stats;
  const _UserList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final users = stats.userStats as List;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(Config.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '录入排行（近7天）',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(Config.textColor)),
          ),
          const SizedBox(height: 12),
          ...users.take(5).map((u) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(Config.primaryColor).withOpacity(0.1),
                  child: Text(
                    u.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(Config.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    u.userName,
                    style: const TextStyle(color: Color(Config.textColor), fontSize: 13),
                  ),
                ),
                Text(
                  '${u.count} 条',
                  style: const TextStyle(
                    color: Color(Config.primaryColor),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
