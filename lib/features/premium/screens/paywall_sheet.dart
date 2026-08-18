import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/purchase_service.dart';

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  Package? _monthlyPackage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await PurchaseService.getOfferings();
      if (offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
        setState(() {
          _monthlyPackage = offerings.current!.availablePackages.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase() async {
    if (_monthlyPackage == null) return;
    try {
      final customerInfo = await PurchaseService.purchasePackage(_monthlyPackage!);
      if (customerInfo?.entitlements.all[AppConstants.revenueCatEntitlementId]?.isActive == true &&
          mounted) {
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Color(0xFF13131F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ORBIT PLUS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade convenience and privacy while keeping core messaging free for everyone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _perkRow(Icons.block, '100% Ad-Free Swiping Deck'),
          _perkRow(Icons.remove_red_eye_outlined, 'See Who Liked You (Instant Matching)'),
          _perkRow(Icons.vpn_key_outlined, 'Unlock Private Vault Albums'),
          _perkRow(Icons.visibility_off_outlined, 'Incognito Browsing Mode'),
          const SizedBox(height: 28),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _purchase,
              child: Text(
                'Subscribe for ${_monthlyPackage?.storeProduct.priceString ?? '\$10.99'} / month',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await PurchaseService.restorePurchases();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Restore Purchases',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perkRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
