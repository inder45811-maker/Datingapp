import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showUGCSafetySheet(BuildContext context, String targetUserId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF13131F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.block_flipped, color: Color(0xFFEF4444)),
              title: const Text(
                'Block User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Instant bidirectional exclusion. Neither of you will see each other.',
              ),
              onTap: () async {
                final myId = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client.from('blocks').insert({
                  'blocker_id': myId,
                  'blocked_id': targetUserId,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: Color(0xFFF59E0B)),
              title: const Text(
                'Report Profile / Content',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Flags account to Trust & Safety for review within 24 hours.',
              ),
              onTap: () async {
                final myId = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client.from('reports').insert({
                  'reporter_id': myId,
                  'reported_id': targetUserId,
                  'reason': 'Objectionable / Inappropriate Content violation',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report received. Our safety team is investigating.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
