/// Domain entity — deliberately Flutter-free (Architecture v1.4, Section 4.2:
/// the domain layer holds pure Dart business rules with no framework deps).
///
/// Mirrors the `accounts` + `subscriptions` tables
/// (Technical Design Document v1.3, Section 3.1).
enum AccountType { individual, consultant, business }

enum SubscriptionTier { free, pro, business }

class Account {
  const Account({
    required this.id,
    required this.ownerUserId,
    required this.accountType,
    required this.displayName,
    required this.tier,
  });

  final String id;
  final String ownerUserId;
  final AccountType accountType;
  final String displayName;
  final SubscriptionTier tier;

  /// Free tier has zero AI/voice access by design (BRD v1.1 decision).
  bool get hasAiAccess => tier != SubscriptionTier.free;

  factory Account.fromMap(Map<String, dynamic> accountRow, Map<String, dynamic> subscriptionRow) {
    return Account(
      id: accountRow['id'] as String,
      ownerUserId: accountRow['owner_user_id'] as String,
      accountType: AccountType.values.byName(accountRow['account_type'] as String),
      displayName: accountRow['display_name'] as String,
      tier: SubscriptionTier.values.byName(subscriptionRow['tier'] as String),
    );
  }
}
