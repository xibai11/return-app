import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/records.dart';
import '../providers/dashboard.dart';
import '../services/api.dart';
import '../config.dart';
import 'dashboard_page.dart';
import 'records_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final ApiService _api;
  late final RecordsProvider _recordsProvider;
  late final DashboardProvider _dashboardProvider;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    final auth = context.read<AuthProvider>();
    // 同步 token
    _recordsProvider = RecordsProvider(_api);
    _dashboardProvider = DashboardProvider(_api);
    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = auth.token;
      if (token != null) {
        _api.setToken(token);
      }
      await _recordsProvider.load(refresh: true);
      await _dashboardProvider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _recordsProvider),
        ChangeNotifierProvider.value(value: _dashboardProvider),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DashboardPage(),
            RecordsPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(Config.borderColor))),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _navItem(0, Icons.dashboard_outlined, Icons.dashboard, '首页'),
                  _navItem(1, Icons.list_alt_outlined, Icons.list_alt, '记录'),
                  _navItem(2, Icons.person_outline, Icons.person, '我的'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? const Color(Config.primaryColor) : const Color(Config.textSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? const Color(Config.primaryColor) : const Color(Config.textSecondary),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
