import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'complete_profile_screen.dart'; // added import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePro extends StatefulWidget {
  const HomePro({Key? key}) : super(key: key);

  @override
  State<HomePro> createState() => _HomeProState();
}

class _HomeProState extends State<HomePro> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkProfileComplete(); // added profile completion check
  }

  Future<void> _loadUser() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _fullName = data['fullName'] ?? 'Technician';
      });
    }
  }

  // added method to check if profile is complete
  Future<void> _checkProfileComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final isComplete = doc.data()?['profileComplete'] ?? false;

    if (!isComplete && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFF97316)),
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
          _buildJobsTab(),
          _buildScheduleTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _statCard('0', 'Today\'s Jobs', const Color(0xFFF97316), Icons.work),
              const SizedBox(width: 12),
              _statCard('0', 'Completed', const Color(0xFF2E5BFF), Icons.check_circle_outline),
              const SizedBox(width: 12),
              _statCard('0 TND', 'Earnings', const Color(0xFF28A745), Icons.payments_outlined),
            ],
          ),
          const SizedBox(height: 28),
          // Availability toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Toggle to accept new jobs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: const Color(0xFFF97316),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Incoming jobs
          const Text(
            'Incoming Jobs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          _incomingJobCard(
            service: 'Plumbing Repair',
            client: 'Ahmed Ben Ali',
            location: 'Tunis, La Marsa',
            time: 'Today, 3:00 PM',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: const Center(
              child: Text('No more incoming jobs', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _incomingJobCard({
    required String service,
    required String client,
    required String location,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('New', style: TextStyle(color: Color(0xFF856404), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(client, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Decline', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return const Center(
      child: Text('My Jobs\n(Coming soon)', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }

  Widget _buildScheduleTab() {
    return const Center(
      child: Text('Schedule\n(Coming soon)', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFF97316).withOpacity(0.1),
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF97316),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Technician', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
          _profileItem(Icons.person_outline, 'Complete Profile', onTap: () { // added onTap
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
            );
          }),
          _profileItem(Icons.build_outlined, 'My Services'),
          _profileItem(Icons.star_outline, 'Reviews'),
          _profileItem(Icons.notifications_outlined, 'Notifications'),
          _profileItem(Icons.help_outline, 'Help & Support'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // updated _profileItem to accept optional onTap
  Widget _profileItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFF97316)),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}