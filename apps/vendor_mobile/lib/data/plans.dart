/// Cefflo subscription plans (V-50..V-54, D-54). Values come from the
/// pricing direction in docs/cefflo/sot/10_PRICING.md §4-8 -- a CANDIDATE,
/// not a Founder-locked price list -- so they live in one place and change
/// here only. Yearly billing follows §Annual: pay ~10 months, get 12.
library;

enum BillingCycle { monthly, yearly }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.tagline,
    required this.deliveries,
    required this.riders,
    required this.zones,
    required this.teamUsers,
    required this.features,
    this.mostPopular = false,
  });

  final String id, name, tagline;
  final int monthlyPrice;

  /// Completed deliveries per billing cycle.
  final int deliveries;

  /// Caps; null = unlimited.
  final int? riders, zones;
  final int teamUsers;
  final List<String> features;
  final bool mostPopular;

  bool get isFree => monthlyPrice == 0;

  /// Price for one billing period of [cycle], in RM.
  int priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.yearly ? monthlyPrice * 10 : monthlyPrice;
}

const subscriptionPlans = [
  SubscriptionPlan(
    id: 'free',
    name: 'Free',
    monthlyPrice: 0,
    tagline: 'Experience Cefflo.',
    deliveries: 100,
    riders: 3,
    zones: 2,
    teamUsers: 1,
    features: [
      '100 deliveries a month',
      'Up to 3 riders · 2 zones',
      'Customer tracking and proof of delivery',
    ],
  ),
  SubscriptionPlan(
    id: 'grow',
    name: 'Grow',
    monthlyPrice: 99,
    tagline: 'For businesses running local deliveries regularly.',
    deliveries: 500,
    riders: 10,
    zones: 5,
    teamUsers: 3,
    features: [
      '500 deliveries a month',
      'Up to 10 riders · 5 zones',
      'Up to 3 team members',
      'Standard reporting and support',
    ],
  ),
  SubscriptionPlan(
    id: 'operate',
    name: 'Operate',
    monthlyPrice: 199,
    tagline: 'Run your local delivery operation in one place.',
    deliveries: 1500,
    riders: null,
    zones: null,
    teamUsers: 10,
    mostPopular: true,
    features: [
      '1,500 deliveries a month',
      'Unlimited riders and zones',
      'Up to 10 team members',
      'Advanced operational reporting',
      'Priority support',
    ],
  ),
  SubscriptionPlan(
    id: 'scale',
    name: 'Scale',
    monthlyPrice: 499,
    tagline: 'For high-volume, complex operations.',
    deliveries: 5000,
    riders: null,
    zones: null,
    teamUsers: 25,
    features: [
      '5,000 deliveries a month',
      'Unlimited riders and zones',
      'Up to 25 team members',
      'Advanced controls and integrations',
      'Priority support',
    ],
  ),
];

SubscriptionPlan planById(String id) =>
    subscriptionPlans.firstWhere((p) => p.id == id);

/// One past invoice (Billing History).
class Invoice {
  const Invoice({
    required this.date,
    required this.amount,
    required this.planName,
    required this.cycle,
    this.paid = true,
  });
  final DateTime date;
  final int amount;
  final String planName;
  final BillingCycle cycle;
  final bool paid;
}
