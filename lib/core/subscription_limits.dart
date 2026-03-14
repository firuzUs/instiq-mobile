/// Лимиты генераций по тарифам (US-7, FLUTTER_DEV_BRIEF).
const Map<String, int> subscriptionLimits = {
  'free': 10,
  'trial': 10,
  'creator': 100,
  'pro': 300,
  'business': -1, // ∞
};

int limitForTier(String? tier) {
  if (tier == null) return 10;
  final v = subscriptionLimits[tier.toLowerCase()];
  return v ?? 10;
}

bool get isUnlimited => false; // use limitForTier('business') == -1

bool hasReachedLimit(int used, String? tier) {
  final limit = limitForTier(tier);
  if (limit < 0) return false;
  return used >= limit;
}
