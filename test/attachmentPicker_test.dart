import 'package:eschool/ui/widgets/attachmentSourceBottomsheet.dart';
import 'package:eschool/utils/attachmentPicker.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// iOS keeps photos and documents behind two different system pickers. Asking
/// `file_picker` for a list of extensions opens the documents browser, which
/// cannot see the photo library at all — so a parent whose receipt was a
/// screenshot could not attach it, and the picker looked broken rather than
/// limited. Android's picker reaches both from one tap and is left alone.

/// Records what the documents picker was asked for, without going near a
/// platform channel.
class _RecordingFilePicker extends FilePicker {
  final List<PlatformFile> files;
  FileType? requestedType;
  List<String>? requestedExtensions;
  bool? requestedMultiple;
  int calls = 0;

  _RecordingFilePicker({this.files = const []});

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    requestedType = type;
    requestedExtensions = allowedExtensions;
    requestedMultiple = allowMultiple;
    return files.isEmpty ? null : FilePickerResult(files);
  }
}

PlatformFile _file(String name) =>
    PlatformFile(name: name, size: 1024, path: '/tmp/$name');

Widget _host(Widget child) => GetMaterialApp(home: Scaffold(body: child));

void main() {
  late _RecordingFilePicker picker;

  setUp(() {
    picker = _RecordingFilePicker();
    FilePicker.platform = picker;
  });

  tearDown(() {
    AttachmentPicker.debugAsksForSource = null;
  });

  group('on a platform whose picker already reaches both', () {
    testWidgets('goes straight to it, with no sheet in the way',
        (tester) async {
      //Android behaviour, unchanged: one tap, the system picker, done
      AttachmentPicker.debugAsksForSource = false;
      picker = _RecordingFilePicker(files: [_file('receipt.pdf')]);
      FilePicker.platform = picker;

      late List<PlatformFile> picked;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await AttachmentPicker.pick(
              context: context,
              allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
            );
          },
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentSourceBottomsheet), findsNothing);
      expect(picker.calls, 1);
      expect(picker.requestedType, FileType.custom);
      expect(picker.requestedExtensions,
          manualPaymentReceiptAllowedFileExtensions);
      expect(picked.single.name, 'receipt.pdf');
    });
  });

  group('on a platform that keeps them apart', () {
    testWidgets('asks which, before opening anything', (tester) async {
      AttachmentPicker.debugAsksForSource = true;

      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () => AttachmentPicker.pick(
            context: context,
            allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
          ),
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      //the photo library is the one that was unreachable, and the one a
      //receipt usually lives in
      expect(find.text(galleryKey), findsOneWidget);
      expect(find.text(cameraKey), findsOneWidget);
      expect(find.text(documentKey), findsOneWidget);
      expect(picker.calls, 0, reason: 'nothing opens until a source is chosen');
    });

    testWidgets('opens the documents browser when that is chosen',
        (tester) async {
      AttachmentPicker.debugAsksForSource = true;
      picker = _RecordingFilePicker(files: [_file('receipt.pdf')]);
      FilePicker.platform = picker;

      late List<PlatformFile> picked;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await AttachmentPicker.pick(
              context: context,
              allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
            );
          },
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(documentKey));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(picker.requestedType, FileType.custom);
      expect(picked.single.name, 'receipt.pdf');
    });

    testWidgets('opens nothing when the sheet is dismissed', (tester) async {
      AttachmentPicker.debugAsksForSource = true;

      late List<PlatformFile> picked;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await AttachmentPicker.pick(
              context: context,
              allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
            );
          },
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      Get.back();
      await tester.pumpAndSettle();

      expect(picker.calls, 0);
      expect(picked, isEmpty);
    });

    testWidgets('leaves the camera out where it makes no sense',
        (tester) async {
      AttachmentPicker.debugAsksForSource = true;

      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () => AttachmentPicker.pick(
            context: context,
            allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
            allowCamera: false,
          ),
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(find.text(cameraKey), findsNothing);
      expect(find.text(galleryKey), findsOneWidget);
      expect(find.text(documentKey), findsOneWidget);
    });
  });

  group('what the endpoint will accept', () {
    const allowed = manualPaymentReceiptAllowedFileExtensions;

    test('takes the types the fee endpoint takes', () {
      for (final name in [
        'receipt.jpg',
        'receipt.jpeg',
        'receipt.png',
        'receipt.pdf',
        'receipt.doc',
        'receipt.docx',
      ]) {
        expect(AttachmentPicker.isSupported(name, allowed), isTrue,
            reason: name);
      }
    });

    test('refuses what it does not', () {
      //an iPhone stores photos as HEIC, and the photo library will hand one
      //back unless the picker re-encodes it — better caught here than by an
      //upload the school never receives
      for (final name in [
        'receipt.heic',
        'clip.mov',
        'archive.zip',
        'receipt',
        'receipt.',
      ]) {
        expect(AttachmentPicker.isSupported(name, allowed), isFalse,
            reason: name);
      }
    });

    test('reads the extension however it is cased', () {
      expect(AttachmentPicker.isSupported('RECEIPT.JPG', allowed), isTrue);
      expect(AttachmentPicker.isSupported('receipt.PnG', allowed), isTrue);
    });

    test('reads the last extension, not the first', () {
      expect(AttachmentPicker.isSupported('receipt.pdf.exe', allowed), isFalse);
      expect(AttachmentPicker.isSupported('my.receipt.png', allowed), isTrue);
    });

    testWidgets('drops what came back unsupported, and says so',
        (tester) async {
      AttachmentPicker.debugAsksForSource = false;
      picker = _RecordingFilePicker(
        files: [_file('receipt.pdf'), _file('clip.mov')],
      );
      FilePicker.platform = picker;

      late List<PlatformFile> picked;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await AttachmentPicker.pick(
              context: context,
              allowedExtensions: allowed,
              allowMultiple: true,
            );
          },
          child: const Text('pick'),
        ),
      )));
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(picked.map((e) => e.name), ['receipt.pdf']);
      expect(find.text(onlyImageOrDocumentFilesAllowedKey), findsOneWidget);

      //the message removes itself on a timer; let it run out so the tree is
      //not torn down with it still pending
      await tester.pump(errorMessageDisplayDuration);
      await tester.pumpAndSettle();
    });
  });
}
