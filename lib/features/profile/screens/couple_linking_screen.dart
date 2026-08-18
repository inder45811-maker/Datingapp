import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

class CoupleLinkingScreen extends ConsumerStatefulWidget {
  const CoupleLinkingScreen({super.key});

  @override
  ConsumerState<CoupleLinkingScreen> createState() => _CoupleLinkingScreenState();
}

class _CoupleLinkingScreenState extends ConsumerState<CoupleLinkingScreen> {
  final TextEditingController _partnerIdController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _linkPartner() async {
    final partnerId = _partnerIdController.text.trim();
    if (partnerId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final myId = SupabaseService.currentUserId;
      if (myId == null) throw Exception('Not authenticated');

      // Verify partner exists
      final partner = await SupabaseService.client
          .from('profiles')
          .select('id, display_name, linked_partner_id')
          .eq('id', partnerId)
          .maybeSingle();

      if (partner == null) {
        throw Exception('Partner profile not found');
      }
      if (partner['linked_partner_id'] != null) {
        throw Exception('That profile is already linked to another partner');
      }

      // Bidirectional link
      await SupabaseService.client
          .from('profiles')
          .update({'linked_partner_id': partnerId})
          .eq('id', myId);

      await SupabaseService.client
          .from('profiles')
          .update({'linked_partner_id': myId})
          .eq('id', partnerId);

      ref.read(authNotifierProvider.notifier).refresh();

      setState(() {
        _statusMessage = 'Successfully linked with ${partner['display_name']}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _isLoading = true);
    try {
      final myId = SupabaseService.currentUserId;
      if (myId == null) return;

      final me = await SupabaseService.client
          .from('profiles')
          .select('linked_partner_id')
          .eq('id', myId)
          .single();

      final partnerId = me['linked_partner_id'] as String?;
      if (partnerId != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'linked_partner_id': null})
            .eq('id', partnerId);
      }
      await SupabaseService.client
          .from('profiles')
          .update({'linked_partner_id': null})
          .eq('id', myId);

      ref.read(authNotifierProvider.notifier).refresh();
      setState(() => _statusMessage = 'Partnership unlinked');
    } catch (e) {
      setState(() => _statusMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Couple Linking')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (profile) {
            final isLinked = profile?.partnerId != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Link your partner profile so the deck shows you as a coupled unit. '
                  'Both parties must consent; the link is bidirectional and visible on both profiles.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 32),
                if (isLinked) ...[
                  Text(
                    'Currently linked to partner ID:\n${profile!.partnerId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: _isLoading ? null : _unlink,
                    child: const Text('Unlink Partner'),
                  ),
                ] else ...[
                  TextField(
                    controller: _partnerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Partner User ID (UUID)',
                      border: OutlineInputBorder(),
                      hintText: 'Paste your partner\'s profile UUID',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _linkPartner,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Request Link'),
                  ),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Successfully') ||
                              _statusMessage!.startsWith('Partnership')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
