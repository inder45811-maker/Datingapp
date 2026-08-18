import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/app_constants.dart';

class PurchaseService {
  static Future<bool> isPremiumActive() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[AppConstants.revenueCatEntitlementId]?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } on PurchasesErrorCode catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }
}
