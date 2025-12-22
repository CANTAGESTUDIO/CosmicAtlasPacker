import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cosmic_atlas_packer/models/sprite_region.dart';
import 'package:cosmic_atlas_packer/services/bin_packing_service.dart';
import 'package:cosmic_atlas_packer/services/export_service.dart';

/// BatchRenderer compatibility tests
///
/// Validates that CosmicAtlasPacker JSON output can be parsed by
/// VariableSizeBatchRenderer as specified in PRD section 10.4
void main() {
  group('BatchRenderer Compatibility', () {
    late ExportService exportService;
    late BinPackingService packingService;

    setUp(() {
      exportService = ExportService();
      packingService = BinPackingService();
    });

    group('JSON Parsing Validation', () {
      test('should produce valid JSON syntax', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'test_atlas.png',
        );

        // Act
        final jsonString = metadata.toJsonString();

        // Assert - should parse without errors
        expect(() => jsonDecode(jsonString), returnsNormally);
      });

      test('should contain all required top-level fields', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'test_atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;

        // Assert - PRD 7.1 required fields
        expect(json.containsKey('version'), true, reason: 'Missing version field');
        expect(json.containsKey('generator'), true, reason: 'Missing generator field');
        expect(json.containsKey('atlas'), true, reason: 'Missing atlas field');
        expect(json.containsKey('sprites'), true, reason: 'Missing sprites field');
        expect(json.containsKey('animations'), true, reason: 'Missing animations field');
        expect(json.containsKey('meta'), true, reason: 'Missing meta field');
      });

      test('should have correct atlas object structure', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'game_atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final atlas = json['atlas'] as Map<String, dynamic>;

        // Assert - BatchRenderer needs these for texture loading
        expect(atlas['file'], 'game_atlas.png');
        expect(atlas['width'], isA<int>());
        expect(atlas['height'], isA<int>());
        expect(atlas['format'], 'RGBA8888');
        expect(atlas['width'], greaterThan(0));
        expect(atlas['height'], greaterThan(0));
      });

      test('should have correct sprite frame structure for VariableSizeBatchRenderer', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'enemy_idle',
            sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
          ),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;
        final sprite = spritesMap['enemy_idle'] as Map<String, dynamic>;
        final frame = sprite['frame'] as Map<String, dynamic>;
        final pivot = sprite['pivot'] as Map<String, dynamic>;

        // Assert - VariableSizeBatchRenderer SpriteFrame requirements
        // PRD 10.4: SpriteFrame needs x, y, width, height, pivotX, pivotY
        expect(frame['x'], isA<int>(), reason: 'frame.x must be int');
        expect(frame['y'], isA<int>(), reason: 'frame.y must be int');
        expect(frame['w'], isA<int>(), reason: 'frame.w must be int');
        expect(frame['h'], isA<int>(), reason: 'frame.h must be int');
        expect(frame['w'], 64, reason: 'frame.w should match sprite width');
        expect(frame['h'], 64, reason: 'frame.h should match sprite height');

        // Pivot is normalized 0.0~1.0
        expect(pivot['x'], isA<double>(), reason: 'pivot.x must be double');
        expect(pivot['y'], isA<double>(), reason: 'pivot.y must be double');
        expect(pivot['x'], inInclusiveRange(0.0, 1.0));
        expect(pivot['y'], inInclusiveRange(0.0, 1.0));
      });

      test('should produce valid frame coordinates within atlas bounds', () {
        // Arrange
        final sprites = [
          SpriteRegion(id: 'sprite_0', sourceRect: const Rect.fromLTWH(0, 0, 64, 64)),
          SpriteRegion(id: 'sprite_1', sourceRect: const Rect.fromLTWH(0, 0, 128, 128)),
          SpriteRegion(id: 'sprite_2', sourceRect: const Rect.fromLTWH(0, 0, 32, 32)),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final atlas = json['atlas'] as Map<String, dynamic>;
        final atlasWidth = atlas['width'] as int;
        final atlasHeight = atlas['height'] as int;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert - all sprites must be within atlas bounds
        for (final entry in spritesMap.entries) {
          final sprite = entry.value as Map<String, dynamic>;
          final frame = sprite['frame'] as Map<String, dynamic>;

          final x = frame['x'] as int;
          final y = frame['y'] as int;
          final w = frame['w'] as int;
          final h = frame['h'] as int;

          expect(x, greaterThanOrEqualTo(0), reason: '${entry.key}: x must be >= 0');
          expect(y, greaterThanOrEqualTo(0), reason: '${entry.key}: y must be >= 0');
          expect(x + w, lessThanOrEqualTo(atlasWidth),
              reason: '${entry.key}: x+w must be <= atlasWidth');
          expect(y + h, lessThanOrEqualTo(atlasHeight),
              reason: '${entry.key}: y+h must be <= atlasHeight');
        }
      });

      test('should have nineSlice field (nullable)', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert - nineSlice field should exist (can be null)
        for (final entry in spritesMap.entries) {
          final sprite = entry.value as Map<String, dynamic>;
          expect(sprite.containsKey('nineSlice'), true,
              reason: '${entry.key}: missing nineSlice field');
          // POC: nineSlice is null
          expect(sprite['nineSlice'], isNull);
        }
      });
    });

    group('Type Verification', () {
      test('should have correct numeric field types', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final atlas = json['atlas'] as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert - atlas dimensions must be integers
        expect(atlas['width'], isA<int>());
        expect(atlas['height'], isA<int>());

        // Assert - frame values must be integers, pivot must be doubles
        for (final entry in spritesMap.entries) {
          final sprite = entry.value as Map<String, dynamic>;
          final frame = sprite['frame'] as Map<String, dynamic>;
          final pivot = sprite['pivot'] as Map<String, dynamic>;

          expect(frame['x'], isA<int>(), reason: '${entry.key}: frame.x must be int');
          expect(frame['y'], isA<int>(), reason: '${entry.key}: frame.y must be int');
          expect(frame['w'], isA<int>(), reason: '${entry.key}: frame.w must be int');
          expect(frame['h'], isA<int>(), reason: '${entry.key}: frame.h must be int');
          expect(pivot['x'], isA<double>(), reason: '${entry.key}: pivot.x must be double');
          expect(pivot['y'], isA<double>(), reason: '${entry.key}: pivot.y must be double');
        }
      });

      test('should have correct string field types', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;

        // Assert
        expect(json['version'], isA<String>());
        expect(json['generator'], isA<String>());
        expect((json['atlas'] as Map)['file'], isA<String>());
        expect((json['atlas'] as Map)['format'], isA<String>());
      });
    });

    group('Edge Cases', () {
      test('should handle empty sprite list', () {
        // Arrange
        final packingResult = packingService.pack([]);

        // Act & Assert - should not crash, but packing result should be empty
        expect(packingResult.packedSprites, isEmpty);
      });

      test('should handle sprite IDs with special characters', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'enemy-idle_01',
            sourceRect: const Rect.fromLTWH(0, 0, 32, 32),
          ),
          SpriteRegion(
            id: 'player.walk.0',
            sourceRect: const Rect.fromLTWH(0, 0, 32, 32),
          ),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert - IDs should be preserved exactly
        expect(spritesMap.containsKey('enemy-idle_01'), true);
        expect(spritesMap.containsKey('player.walk.0'), true);
      });

      test('should handle single sprite', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'single_sprite',
            sourceRect: const Rect.fromLTWH(0, 0, 256, 256),
          ),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert
        expect(spritesMap.length, 1);
        expect(spritesMap.containsKey('single_sprite'), true);
      });

      test('should handle many sprites', () {
        // Arrange
        final sprites = List.generate(
          100,
          (i) => SpriteRegion(
            id: 'sprite_$i',
            sourceRect: const Rect.fromLTWH(0, 0, 32, 32),
          ),
        );
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final spritesMap = json['sprites'] as Map<String, dynamic>;

        // Assert
        expect(spritesMap.length, 100);
        for (int i = 0; i < 100; i++) {
          expect(spritesMap.containsKey('sprite_$i'), true,
              reason: 'Missing sprite_$i');
        }
      });
    });

    group('VariableSizeBatchRenderer Integration', () {
      test('should be parseable into SpriteFrame map', () {
        // This test simulates how VariableSizeBatchRenderer would load the JSON

        // Arrange
        final sprites = [
          SpriteRegion(id: 'enemy_idle', sourceRect: const Rect.fromLTWH(0, 0, 64, 64)),
          SpriteRegion(id: 'enemy_walk_0', sourceRect: const Rect.fromLTWH(0, 0, 64, 64)),
          SpriteRegion(id: 'button_normal', sourceRect: const Rect.fromLTWH(0, 0, 128, 48)),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'sprites_atlas.png',
          pivotX: 0.5,
          pivotY: 1.0, // bottom-center pivot
        );

        // Act - simulate VariableSizeBatchRenderer loading
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final frames = _parseToSpriteFrameMap(json);

        // Assert
        expect(frames.length, 3);
        expect(frames['enemy_idle'], isNotNull);
        expect(frames['enemy_idle']!.width, 64);
        expect(frames['enemy_idle']!.height, 64);
        expect(frames['enemy_idle']!.pivotX, 0.5);
        expect(frames['enemy_idle']!.pivotY, 1.0);

        expect(frames['button_normal']!.width, 128);
        expect(frames['button_normal']!.height, 48);
      });

      test('should provide correct texture coordinates for rendering', () {
        // Arrange
        final sprites = [
          SpriteRegion(id: 'sprite_a', sourceRect: const Rect.fromLTWH(0, 0, 64, 64)),
        ];
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final frames = _parseToSpriteFrameMap(json);
        final frame = frames['sprite_a']!;

        // Simulate texture coordinate calculation (as in PRD 10.4)
        final tx0 = frame.x.toDouble();
        final ty0 = frame.y.toDouble();
        final tx1 = (frame.x + frame.width).toDouble();
        final ty1 = (frame.y + frame.height).toDouble();

        // Assert - texture coordinates should be valid pixel coordinates
        expect(tx0, greaterThanOrEqualTo(0));
        expect(ty0, greaterThanOrEqualTo(0));
        expect(tx1, greaterThan(tx0));
        expect(ty1, greaterThan(ty0));
        expect(tx1 - tx0, 64); // width
        expect(ty1 - ty0, 64); // height
      });
    });

    group('Meta Object Validation', () {
      test('should have valid meta object structure', () {
        // Arrange
        final sprites = _createTestSprites();
        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final json = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;
        final meta = json['meta'] as Map<String, dynamic>;

        // Assert
        expect(meta.containsKey('createdAt'), true);
        expect(meta.containsKey('app'), true);
        expect(meta.containsKey('appVersion'), true);
        expect(meta['app'], 'CosmicAtlasPacker');
        expect(meta['createdAt'], isA<String>());
        // createdAt should be ISO 8601 format
        expect(() => DateTime.parse(meta['createdAt'] as String), returnsNormally);
      });
    });
  });
}

/// Helper function to create test sprites
List<SpriteRegion> _createTestSprites() {
  return [
    SpriteRegion(id: 'sprite_0', sourceRect: const Rect.fromLTWH(0, 0, 64, 64)),
    SpriteRegion(id: 'sprite_1', sourceRect: const Rect.fromLTWH(0, 0, 32, 32)),
    SpriteRegion(id: 'sprite_2', sourceRect: const Rect.fromLTWH(0, 0, 128, 64)),
  ];
}

/// Simulates SpriteFrame class from PRD 10.4
class _SpriteFrame {
  final int x, y, width, height;
  final double pivotX, pivotY;

  _SpriteFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pivotX,
    required this.pivotY,
  });
}

/// Parse JSON to Map<String, SpriteFrame> as VariableSizeBatchRenderer would
Map<String, _SpriteFrame> _parseToSpriteFrameMap(Map<String, dynamic> json) {
  final sprites = json['sprites'] as Map<String, dynamic>;
  final result = <String, _SpriteFrame>{};

  for (final entry in sprites.entries) {
    final sprite = entry.value as Map<String, dynamic>;
    final frame = sprite['frame'] as Map<String, dynamic>;
    final pivot = sprite['pivot'] as Map<String, dynamic>;

    result[entry.key] = _SpriteFrame(
      x: frame['x'] as int,
      y: frame['y'] as int,
      width: frame['w'] as int,
      height: frame['h'] as int,
      pivotX: (pivot['x'] as num).toDouble(),
      pivotY: (pivot['y'] as num).toDouble(),
    );
  }

  return result;
}
