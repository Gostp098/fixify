import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart' as app;
import '../../providers/technician_profile_provider.dart';
import 'complete_profile_screen.dart';
import 'incoming_jobs_screen.dart';
import 'my_jobs_screen.dart';

class HomePro extends StatefulWidget {
  const HomePro({Key? key}) : super(key: key);

  @override
  State<HomePro> createState() => _HomeProState();
}

class _HomeProState extends State<HomePro> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  String _fullName = '';
  bool _isLoadingUser = true;

  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _authService.getUserData();
    if (!mounted) return;

    final isComplete = data['profileComplete'] as bool? ?? false;

    if (!isComplete) {
      // No flash — redirect immediately to profile setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
      return;
    }

    // Load technician profile into provider for the dashboard
    await context.read<TechnicianProfileProvider>().loadProfile();
    if (!mounted) return;

    setState(() {
      _fullName = data['fullName'] as String? ?? 'Technician';
      _isLoadingUser = false;
    });
  }

  Future<void> _logout() async {
    await context.read<app.AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: _orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_fullName.split(' ').first} 🔧',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const Text(
              'Ready for today\'s jobs?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _orange),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const IncomingJobsScreen(),
          const MyJobsScreen(),
          _buildScheduleTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: _orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined), label: 'Incoming'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline), label: 'My Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // ── Dashboard tab ─────────────────────────────────────────

  Widget _buildDashboardTab() {
    return Consumer<TechnicianProfileProvider>(
      builder: (context, techProvider, _) {
        final isOnline = techProvider.profile?.isOnline ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(
                children: [
                  _statCard('0', 'Today\'s Jobs', _orange,
                      Icons.work),
                  const SizedBox(width: 12),
                  _statCard('0', 'Completed',
                      const Color(0xFF2E5BFF), Icons.check_circle_outline),
                  const SizedBox(width: 12),
                  _statCard('0 TND', 'Earnings',
                      const Color(0xFF28A745), Icons.payments_outlined),
                ],
              ),
              const SizedBox(height: 28),

              // Availability toggle — now wired to provider
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Availability',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                          isOnline ? 'Online — accepting jobs' : 'Offline',
                          style: TextStyle(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: (v) =>
                          techProvider.toggleOnline(v),
                      activeColor: _orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Incoming jobs (placeholder until BookingProvider)
              const Text(
                'Incoming Jobs',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No incoming jobs yet.\nMake sure you\'re online to receive requests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── Jobs tab ──────────────────────────────────────────────

  Widget _buildJobsTab() => const MyJobsScreen();

  // ── Schedule tab ──────────────────────────────────────────

  Widget _buildScheduleTab() {
    return const Center(
      child: Text(
        'Schedule\n(Coming soon)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  // ── Profile tab ───────────────────────────────────────────

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: _orange.withOpacity(0.1),
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(_fullName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Technician',
                  style: TextStyle(
                      color: _orange, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
          _profileItem(Icons.person_outline, 'Edit Profile', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompleteProfileScreen()),
            );
          }),
          _profileItem(Icons.build_outlined, 'My Services'),
          _profileItem(Icons.star_outline, 'Reviews'),
          _profileItem(
              Icons.notifications_outlined, 'Notifications'),
          _profileItem(Icons.help_outline, 'Help & Support'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label,
      {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _orange),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
