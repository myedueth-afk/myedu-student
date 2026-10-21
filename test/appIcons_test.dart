import 'dart:io';

import 'package:eschool/utils/appIcons.dart';
import 'package:eschool/utils/svgColorSwap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// The icons take the school's primary colour at runtime. An icon that is
// missing, fails to parse or carries a second colour only shows up as a blank
// or half-painted tile on a device, so every asset is checked here.

const Color _schoolPrimary = Color(0xffC2185B);
const Color _schoolSecondary = Color(0xff101010);

/// Counts how often each source colour of [swap] was repainted.
class _RecordingSwap extends ColorMapper {
  final SvgColorSwap swap;
  final Map<Color, int> hits = {};

  _RecordingSwap(this.swap);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final swapped = swap.substitute(id, elementName, attributeName, color);
    if (swapped != color) {
      final source = swap.swaps.keys.firstWhere(
        (key) => (key.toARGB32() & 0xffffff) == (color.toARGB32() & 0xffffff),
      );
      hits[source] = (hits[source] ?? 0) + 1;
    }
    return swapped;
  }
}

List<File> _svgsIn(String directory, {String prefix = ''}) {
  final files = Directory(directory)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.svg'))
      .where((file) => file.uri.pathSegments.last.startsWith(prefix))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// Colours an SVG paints with, leaving out clip shapes, which paint nothing.
Set<String> _paintedColors(String svg) {
  final visible =
      svg.replaceAll(RegExp(r'<clipPath[\s\S]*?</clipPath>'), '');
  return RegExp(r'''(?:fill|stroke|stop-color)="(#[0-9a-fA-F]{3,8})"''')
      .allMatches(visible)
      .map((match) => match.group(1)!.toUpperCase())
      .toSet();
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();

Future<_RecordingSwap> _parse(
  WidgetTester tester,
  File file,
  Map<Color, Color> swaps,
) async {
  final recorder = _RecordingSwap(SvgColorSwap(swaps));
  final bytes = await tester.runAsync(
    () => SvgStringLoader(file.readAsStringSync(), colorMapper: recorder)
        .loadBytes(null),
  );
  expect(bytes!.lengthInBytes, greaterThan(0), reason: '${file.path} is empty');
  return recorder;
}

void main() {
  final menuIcons = _svgsIn('assets/icons', prefix: 'menu_');
  final navIcons = _svgsIn('assets/icons', prefix: 'nav_');
  final illustrations = _svgsIn('assets/illustrations');

  test('every path the app refers to is a bundled file', () {
    final registry = File('lib/utils/appIcons.dart').readAsStringSync();
    final icons = RegExp(r'"\$_dir/((?:menu|nav)_\w+\.svg)"')
        .allMatches(registry)
        .map((match) => 'assets/icons/${match.group(1)}');
    final pictures = RegExp(r'"\$_dir/((?!menu_|nav_)\w+\.svg)"')
        .allMatches(registry)
        .map((match) => 'assets/illustrations/${match.group(1)}');
    final legacy = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand(
          (file) => RegExp(r'''getImagePath\(\s*["']([^"']+)["']''')
              .allMatches(file.readAsStringSync())
              .map((match) => 'assets/images/${match.group(1)}'),
        );

    expect(icons, isNotEmpty);
    expect(pictures, isNotEmpty);
    for (final path in {...icons, ...pictures, ...legacy}) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }

    // And the other way round: nothing is bundled that no screen can show.
    final referenced = {...icons, ...pictures};
    for (final file in [...menuIcons, ...navIcons, ...illustrations]) {
      expect(referenced, contains(file.path),
          reason: '${file.path} has no entry in appIcons.dart');
    }
  });

  test('the registry points at the files the tests cover', () {
    expect(File(AppIcons.attendance).existsSync(), isTrue);
    expect(File(AppIcons.navHomeActive).existsSync(), isTrue);
    expect(File(AppIllustrations.noData).existsSync(), isTrue);
  });

  group('menu icons', () {
    test('are drawn in one colour, so a tint repaints all of them', () {
      expect(menuIcons, isNotEmpty);
      for (final file in menuIcons) {
        expect(
          _paintedColors(file.readAsStringSync()),
          {_hex(SvgSourceColors.brand)},
          reason: '${file.path} needs a single-colour export',
        );
      }
    });

    for (final file in menuIcons) {
      testWidgets('${file.uri.pathSegments.last} parses', (tester) async {
        await _parse(tester, file, {});
      });
    }
  });

  group('bottom navigation icons', () {
    final swaps = {
      SvgSourceColors.navOutline: _schoolSecondary,
      SvgSourceColors.accent: _schoolPrimary,
    };

    for (final file in navIcons) {
      final selected = file.path.endsWith('_active.svg');

      testWidgets('${file.uri.pathSegments.last} follows the theme',
          (tester) async {
        expect(
          _paintedColors(file.readAsStringSync()),
          {
            _hex(SvgSourceColors.navOutline),
            if (selected) _hex(SvgSourceColors.accent),
          },
          reason: '${file.path} paints a colour the theme does not replace',
        );

        final recorder = await _parse(tester, file, swaps);
        expect(recorder.hits[SvgSourceColors.navOutline], greaterThan(0));
        expect(
          recorder.hits.containsKey(SvgSourceColors.accent),
          selected,
          reason: 'only the selected icon is filled with the accent colour',
        );
      });
    }
  });

  group('illustrations', () {
    for (final file in illustrations) {
      testWidgets('${file.uri.pathSegments.last} takes the primary colour',
          (tester) async {
        final recorder = await _parse(
          tester,
          file,
          {SvgSourceColors.brand: _schoolPrimary},
        );
        expect(recorder.hits[SvgSourceColors.brand], greaterThan(0),
            reason: '${file.path} has no brand-coloured part to repaint');
      });
    }
  });

  group('SvgColorSwap', () {
    final swap = SvgColorSwap({SvgSourceColors.brand: _schoolPrimary});

    test('repaints the source colour and keeps its transparency', () {
      expect(
        swap.substitute(null, 'path', 'fill', SvgSourceColors.brand),
        _schoolPrimary,
      );
      final faded = swap.substitute(
        null,
        'path',
        'fill',
        SvgSourceColors.brand.withValues(alpha: 0.5),
      );
      expect(faded.a, closeTo(0.5, 0.01));
      expect(faded.toARGB32() & 0xffffff, _schoolPrimary.toARGB32() & 0xffffff);
    });

    test('leaves every other colour as drawn', () {
      const skin = Color(0xffFFAA9D);
      expect(swap.substitute(null, 'path', 'fill', skin), skin);
    });

    test('is equal by palette, so the picture cache is shared', () {
      final same = SvgColorSwap({SvgSourceColors.brand: _schoolPrimary});
      final other = SvgColorSwap({SvgSourceColors.brand: Colors.black});
      expect(same, swap);
      expect(same.hashCode, swap.hashCode);
      expect(other, isNot(swap));
    });
  });
}
