import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionFlow extends StatefulWidget {
  const AccountDeletionFlow({super.key});

  @override
  State<AccountDeletionFlow> createState() => _AccountDeletionFlowState();
}

class _AccountDeletionFlowState extends State<AccountDeletionFlow> {
  bool _isDeleting = false;

  Future<void> _executePermanentPurge() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    try {
      // Call the service-role edge function that deletes both the profile
      // (with cascades) and the auth.users record – required by Apple 5.1.1.
      final response = await Supabase.instance.client.functions.invoke(
        'delete-user',
        headers: {
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Deletion failed');
      }

      // Ensure local session is cleared
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
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
              'Executing this action instantly erases your profile metadata, matches, photo records, real-time chat histories, '
              'and the underlying authentication record. This cannot be undone.',
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
              onPressed: _isDeleting ? null : _executePermanentPurge,
              child: _isDeleting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
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
