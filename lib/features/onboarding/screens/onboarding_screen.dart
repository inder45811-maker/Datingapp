import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../deck/screens/swipe_deck_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _birthdate;
  String _gender = 'other';
  final List<String> _selectedDesires = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _genderOptions = [
    'man',
    'woman',
    'non_binary',
    'couple',
    'trans',
    'other',
  ];

  final List<String> _desireOptions = [
    'monogamish',
    'polyamorous',
    'open_relationship',
    'casual',
    'curious',
    'kink',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().length < 2) {
      setState(() => _error = 'Display name must be at least 2 characters');
      return;
    }
    if (_birthdate == null) {
      setState(() => _error = 'Please select your date of birth');
      return;
    }

    final age = DateTime.now().difference(_birthdate!).inDays ~/ 365;
    if (age < 18) {
      setState(() => _error = 'You must be 18 or older to use Orbit');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Request location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for discovery');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final locationWkt =
          'SRID=4326;POINT(${position.longitude} ${position.latitude})';

      // Upsert a complete profile
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': _nameController.text.trim(),
        'birthdate': _birthdate!.toIso8601String().split('T').first,
        'bio': _bioController.text.trim(),
        'gender': _gender,
        'desires': _selectedDesires,
        'location': locationWkt,
        'photos': ['https://placehold.co/600x800.png'], // User must replace later
      });

      await ref.read(authNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SwipeDeckScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF8B5CF6)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      appBar: AppBar(
        title: const Text('Complete your profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us a little about yourself. This information is required before you can start discovering people.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _birthdate == null
                      ? 'Date of birth'
                      : 'Born ${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white54),
                onTap: _pickBirthdate,
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),

              const Text('Gender identity', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _genderOptions.map((g) {
                  final selected = _gender == g;
                  return ChoiceChip(
                    label: Text(g.replaceAll('_', ' ')),
                    selected: selected,
                    onSelected: (_) => setState(() => _gender = g),
                    selectedColor: const Color(0xFF8B5CF6),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('Relationship desires', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _desireOptions.map((d) {
                  final selected = _selectedDesires.contains(d);
                  return FilterChip(
                    label: Text(d.replaceAll('_', ' ')),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDesires.add(d);
                        } else {
                          _selectedDesires.remove(d);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF8B5CF6),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Short bio (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be able to add real photos later. A placeholder is used for now so discovery can begin.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Start exploring',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
