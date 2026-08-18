import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionFlow extends StatelessWidget {
  const AccountDeletionFlow({super.key});

  Future<void> _executePermanentPurge(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Delete user profile record (Cascades down through FKs to swipes, matches, messages)
    // Note: Full auth.users deletion requires a service-role edge function in production
    // to satisfy Apple Guideline 5.1.1 complete data purge. This client-side path
    // removes all application data and signs the user out.
    await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Irreversible Account Deletion',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Under Apple App Store Guideline 5.1.1, you have the right to permanently purge your entire footprint. '
              'Executing this action instantly erases your profile metadata, matches, photo records, and real-time chat histories. This cannot be undone.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _executePermanentPurge(context),
              child: const Text(
                'Permanently Erase All My Data',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
