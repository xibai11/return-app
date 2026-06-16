import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/records.dart';
import '../config.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          final user = auth.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 头像 & 名称
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(Config.borderColor)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(Config.primaryColor).withOpacity(0.1),
                      child: Text(
                        (user?.name ?? user?.username ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(Config.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? user?.username ?? '用户',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(Config.textColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user?.username ?? '-'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(Config.textSecondary),
                            ),
                          ),
                          if (user?.role == 'admin')
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(Config.primaryColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '管理员',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(Config.dangerColor)),
                      tooltip: '退出登录',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('退出登录'),
                            content: const Text('确定要退出当前账号吗？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: const Color(Config.dangerColor)),
                                child: const Text('退出'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          context.read<AuthProvider>().logout();
                          context.read<RecordsProvider>().clear();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 数据统计
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(Config.borderColor)),
                ),
                child: Consumer<RecordsProvider>(
                  builder: (ctx, records, _) {
                    final total = records.records.length;
                    final pending = records.records.where((r) => r.status == 'pending').length;
                    final completed = records.records.where((r) => r.status == 'completed').length;
                    final important = records.records.where((r) => r.isImportant == true).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '我的数据概览',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(Config.textColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _miniStat('总记录', '$total', const Color(Config.textColor)),
                            _miniStat('待处理', '$pending', const Color(Config.dangerColor)),
                            _miniStat('已完成', '$completed', const Color(Config.successColor)),
                            _miniStat('重点', '$important', const Color(Config.warningColor)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 关于
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(Config.borderColor)),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.info_outline,
                      label: '版本信息',
                      trailing: const Text('v1.0.0', style: TextStyle(fontSize: 13, color: Color(Config.textSecondary))),
                    ),
                    const Divider(height: 1),
                    _menuItem(
                      icon: Icons.cloud_outlined,
                      label: '服务器地址',
                      trailing: const Text('103.236.96.82:26821',
                          style: TextStyle(fontSize: 12, color: Color(Config.textSecondary))),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(Config.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(Config.textSecondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15, color: Color(Config.textColor))),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
