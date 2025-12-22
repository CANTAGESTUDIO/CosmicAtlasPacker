import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cosmic_atlas_packer/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CosmicAtlasPackerApp(),
      ),
    );

    // Verify app title is displayed
    expect(find.text('CosmicAtlasPacker'), findsOneWidget);
    expect(find.text('Texture Packing Editor'), findsOneWidget);
  });
}
