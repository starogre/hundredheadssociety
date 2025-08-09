class AwardCacheService {
  // Cache for awards data
  static final Map<String, int> _trophyCache = {};
  static final Map<String, List<String>> _merchCache = {};

  // Get cached trophy count
  static int? getCachedTrophyCount(String userId) {
    return _trophyCache[userId];
  }

  // Set cached trophy count
  static void setCachedTrophyCount(String userId, int count) {
    _trophyCache[userId] = count;
  }

  // Get cached merch items
  static List<String>? getCachedMerchItems(String userId) {
    return _merchCache[userId];
  }

  // Set cached merch items
  static void setCachedMerchItems(String userId, List<String> items) {
    _merchCache[userId] = List.from(items);
  }

  // Add merch item to cache
  static void addMerchItemToCache(String userId, String item) {
    if (_merchCache.containsKey(userId)) {
      _merchCache[userId]!.add(item);
    } else {
      _merchCache[userId] = [item];
    }
  }

  // Remove merch item from cache
  static void removeMerchItemFromCache(String userId, String item) {
    if (_merchCache.containsKey(userId)) {
      _merchCache[userId]!.remove(item);
    }
  }

  // Clear cache for a specific user
  static void clearCache(String userId) {
    _trophyCache.remove(userId);
    _merchCache.remove(userId);
  }

  // Clear all cache
  static void clearAllCache() {
    _trophyCache.clear();
    _merchCache.clear();
  }
} 