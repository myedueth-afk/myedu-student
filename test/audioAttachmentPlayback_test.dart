import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/ui/widgets/audioPlayerBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/studyMaterialWithDownloadButtonContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audio attachments (e.g. assignment reference files) play inside the app
/// instead of being downloaded and handed to another app.
void main() {
  StudyMaterial material({
    String type = "1",
    String extension = "",
    String url = "https://example.com/storage/629/files/abc.bin",
    String typeDetail = "File Upload",
  }) =>
      StudyMaterial.fromJson({
        'id': 1,
        'type': type,
        'file_name': 'Chapter 4 reading',
        'file_url': url,
        'file_extension': extension,
        'type_detail': typeDetail,
      });

  group('isAudio', () {
    test('uploaded audio files are detected by their extension', () {
      for (final extension in ['mp3', 'MP3', '.m4a', 'aac', 'wav', 'mpga']) {
        expect(material(extension: extension).isAudio, isTrue,
            reason: extension);
      }
    });

    test('falls back to the url when the extension is missing', () {
      expect(
        material(url: 'https://example.com/storage/files/abc.mp3').isAudio,
        isTrue,
      );
      expect(
        material(url: 'https://example.com/files/abc.mp3?token=1').isAudio,
        isTrue,
        reason: 'query string is not part of the extension',
      );
      expect(material(url: 'https://example.com/files/abc').isAudio, isFalse);
    });

    test('other files are not treated as audio', () {
      for (final extension in ['jpeg', 'pdf', 'mp4', 'docx']) {
        expect(material(extension: extension).isAudio, isFalse,
            reason: extension);
      }
    });

    test('only uploaded files count, not links or videos', () {
      expect(material(type: "2", extension: 'mp3').isAudio, isFalse);
      expect(material(type: "3", extension: 'mp3').isAudio, isFalse);
      expect(
        material(type: "4", extension: 'mp3', typeDetail: 'Other Link')
            .isAudio,
        isFalse,
      );
    });
  });

  group('formatPlaybackTime', () {
    String format(Duration duration) =>
        AudioPlayerBottomsheetContainer.formatPlaybackTime(duration);

    test('formats minutes and seconds', () {
      expect(format(Duration.zero), '0:00');
      expect(format(const Duration(seconds: 9)), '0:09');
      expect(format(const Duration(seconds: 60)), '1:00');
      expect(format(const Duration(minutes: 12, seconds: 5)), '12:05');
      expect(format(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('adds hours from one hour on', () {
      expect(format(const Duration(hours: 1)), '1:00:00');
      expect(format(const Duration(hours: 2, minutes: 3, seconds: 4)),
          '2:03:04');
    });

    test('drops milliseconds and never goes negative', () {
      expect(format(const Duration(seconds: 5, milliseconds: 999)), '0:05');
      expect(format(const Duration(seconds: -3)), '0:00');
    });
  });

  group('attachment tile', () {
    Future<void> pumpTile(WidgetTester tester, StudyMaterial studyMaterial) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) =>
                  StudyMaterialWithDownloadButtonContainer(
                boxConstraints: constraints,
                studyMaterial: studyMaterial,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('audio files show a play button', (tester) async {
      await pumpTile(tester, material(extension: 'mp3'));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('other files do not', (tester) async {
      await pumpTile(tester, material(extension: 'pdf'));
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });
  });
}
