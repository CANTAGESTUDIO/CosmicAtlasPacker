import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bin_packing_service.dart';
import 'multi_sprite_provider.dart';
import 'packing_provider.dart';

/// Provider for packing result with all sprites from all sources
final multiPackingResultProvider = Provider<PackingResult?>((ref) {
  final multiSpriteState = ref.watch(multiSpriteProvider);
  final settings = ref.watch(atlasSettingsProvider);
  final packingService = ref.watch(binPackingServiceProvider);

  final allSprites = multiSpriteState.allSprites;
  if (allSprites.isEmpty) {
    return null;
  }

  return packingService.pack(
    allSprites,
    maxWidth: settings.maxWidth,
    maxHeight: settings.maxHeight,
    padding: settings.padding,
    powerOfTwo: settings.powerOfTwo,
  );
});

/// Provider for combined atlas dimensions
final multiAtlasSizeProvider = Provider<(int, int)>((ref) {
  final result = ref.watch(multiPackingResultProvider);
  if (result == null) return (0, 0);
  return (result.atlasWidth, result.atlasHeight);
});

/// Provider for combined packing efficiency
final multiPackingEfficiencyProvider = Provider<double>((ref) {
  final result = ref.watch(multiPackingResultProvider);
  if (result == null) return 0.0;
  return result.efficiency * 100;
});

/// Provider for sprite count by source
final spriteCountBySourceProvider = Provider<Map<String, int>>((ref) {
  final multiSpriteState = ref.watch(multiSpriteProvider);
  final counts = <String, int>{};

  for (final entry in multiSpriteState.spritesBySource.entries) {
    counts[entry.key] = entry.value.length;
  }

  return counts;
});
