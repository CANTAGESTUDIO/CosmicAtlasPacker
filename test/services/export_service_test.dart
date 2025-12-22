import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cosmic_atlas_packer/models/sprite_region.dart';
import 'package:cosmic_atlas_packer/services/bin_packing_service.dart';
import 'package:cosmic_atlas_packer/services/export_service.dart';

void main() {
  group('ExportService', () {
    late ExportService exportService;
    late BinPackingService packingService;

    setUp(() {
      exportService = ExportService();
      packingService = BinPackingService();
    });

    group('generateMetadata', () {
      test('should generate valid metadata from packing result', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'sprite_0',
            sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
          ),
          SpriteRegion(
            id: 'sprite_1',
            sourceRect: const Rect.fromLTWH(0, 64, 32, 32),
          ),
        ];

        final packingResult = packingService.pack(sprites);

        // Act
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'test_atlas.png',
        );

        // Assert
        expect(metadata.version, '1.0.0');
        expect(metadata.generator, 'CosmicAtlasPacker');
        expect(metadata.atlas.file, 'test_atlas.png');
        expect(metadata.atlas.format, 'RGBA8888');
        expect(metadata.sprites.length, 2);
        expect(metadata.sprites.containsKey('sprite_0'), true);
        expect(metadata.sprites.containsKey('sprite_1'), true);
      });

      test('should generate correct frame data for each sprite', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'enemy_idle',
            sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
          ),
        ];

        final packingResult = packingService.pack(sprites);

        // Act
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Assert
        final spriteInfo = metadata.sprites['enemy_idle']!;
        expect(spriteInfo.frame.w, 64);
        expect(spriteInfo.frame.h, 64);
        expect(spriteInfo.pivot.x, 0.5);
        expect(spriteInfo.pivot.y, 0.5);
        expect(spriteInfo.nineSlice, null);
      });

      test('should include correct atlas dimensions', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'large_sprite',
            sourceRect: const Rect.fromLTWH(0, 0, 256, 128),
          ),
        ];

        final packingResult = packingService.pack(sprites);

        // Act
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Assert
        expect(metadata.atlas.width, greaterThanOrEqualTo(256));
        expect(metadata.atlas.height, greaterThanOrEqualTo(128));
      });

      test('should support custom pivot values', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'bottom_pivot',
            sourceRect: const Rect.fromLTWH(0, 0, 32, 32),
          ),
        ];

        final packingResult = packingService.pack(sprites);

        // Act
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
          pivotX: 0.5,
          pivotY: 1.0, // Bottom center pivot
        );

        // Assert
        final spriteInfo = metadata.sprites['bottom_pivot']!;
        expect(spriteInfo.pivot.x, 0.5);
        expect(spriteInfo.pivot.y, 1.0);
      });
    });

    group('toJsonString', () {
      test('should produce valid JSON', () {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'test_sprite',
            sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
          ),
        ];

        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'atlas.png',
        );

        // Act
        final jsonString = metadata.toJsonString();

        // Assert - should be valid JSON
        expect(() => jsonDecode(jsonString), returnsNormally);

        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(parsed['version'], '1.0.0');
        expect(parsed['generator'], 'CosmicAtlasPacker');
        expect(parsed['atlas']['file'], 'atlas.png');
        expect(parsed['sprites']['test_sprite']['frame']['w'], 64);
      });

      test('should match PRD section 7.1 schema structure', () {
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
          atlasFileName: 'sprites_atlas.png',
        );

        // Act
        final parsed = jsonDecode(metadata.toJsonString()) as Map<String, dynamic>;

        // Assert - verify PRD 7.1 schema structure
        expect(parsed.containsKey('version'), true);
        expect(parsed.containsKey('generator'), true);
        expect(parsed.containsKey('atlas'), true);
        expect(parsed.containsKey('sprites'), true);
        expect(parsed.containsKey('animations'), true);
        expect(parsed.containsKey('meta'), true);

        // Atlas structure
        final atlas = parsed['atlas'] as Map<String, dynamic>;
        expect(atlas.containsKey('file'), true);
        expect(atlas.containsKey('width'), true);
        expect(atlas.containsKey('height'), true);
        expect(atlas.containsKey('format'), true);

        // Sprite structure
        final sprite = (parsed['sprites'] as Map<String, dynamic>)['enemy_idle'] as Map<String, dynamic>;
        expect(sprite.containsKey('frame'), true);
        expect(sprite.containsKey('pivot'), true);
        expect(sprite.containsKey('nineSlice'), true);

        // Frame structure
        final frame = sprite['frame'] as Map<String, dynamic>;
        expect(frame.containsKey('x'), true);
        expect(frame.containsKey('y'), true);
        expect(frame.containsKey('w'), true);
        expect(frame.containsKey('h'), true);

        // Pivot structure
        final pivot = sprite['pivot'] as Map<String, dynamic>;
        expect(pivot.containsKey('x'), true);
        expect(pivot.containsKey('y'), true);

        // Meta structure
        final meta = parsed['meta'] as Map<String, dynamic>;
        expect(meta.containsKey('createdAt'), true);
        expect(meta.containsKey('app'), true);
        expect(meta.containsKey('appVersion'), true);
      });
    });

    group('getJsonPathFromPngPath', () {
      test('should replace .png extension with .json', () {
        expect(
          exportService.getJsonPathFromPngPath('/path/to/atlas.png'),
          '/path/to/atlas.json',
        );
      });

      test('should handle uppercase extension', () {
        expect(
          exportService.getJsonPathFromPngPath('/path/to/atlas.PNG'),
          '/path/to/atlas.json',
        );
      });

      test('should append .json if no .png extension', () {
        expect(
          exportService.getJsonPathFromPngPath('/path/to/atlas'),
          '/path/to/atlas.json',
        );
      });
    });

    group('exportJson', () {
      test('should write valid JSON file', () async {
        // Arrange
        final sprites = [
          SpriteRegion(
            id: 'test_sprite',
            sourceRect: const Rect.fromLTWH(0, 0, 64, 64),
          ),
        ];

        final packingResult = packingService.pack(sprites);
        final metadata = exportService.generateMetadata(
          packingResult: packingResult,
          atlasFileName: 'test.png',
        );

        final tempDir = Directory.systemTemp;
        final outputPath = '${tempDir.path}/test_export_${DateTime.now().millisecondsSinceEpoch}.json';

        try {
          // Act
          await exportService.exportJson(
            metadata: metadata,
            outputPath: outputPath,
          );

          // Assert
          final file = File(outputPath);
          expect(await file.exists(), true);

          final content = await file.readAsString();
          final parsed = jsonDecode(content) as Map<String, dynamic>;
          expect(parsed['generator'], 'CosmicAtlasPacker');
        } finally {
          // Cleanup
          final file = File(outputPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      });
    });
  });
}
