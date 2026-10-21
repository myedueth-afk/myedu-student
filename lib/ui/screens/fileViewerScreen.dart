import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

class FileViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const FileViewerScreen({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return FileViewerScreen(
      fileUrl: arguments['fileUrl'] as String,
      fileName: arguments['fileName'] as String,
    );
  }
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late FileType _fileType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fileType = _getFileType(widget.fileUrl);
  }

  /// Determines the file type based on the file extension
  FileType _getFileType(String url) {
    final extension = url.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return FileType.image;
    } else if (extension == 'pdf') {
      return FileType.pdf;
    } else {
      return FileType.other;
    }
  }

  /// Builds the appropriate viewer based on file type
  Widget _buildFileViewer() {
    switch (_fileType) {
      case FileType.image:
        return _buildImageViewer();
      case FileType.pdf:
      case FileType.other:
        return _buildWebViewer();
    }
  }

  /// Builds an image viewer with pinch-to-zoom functionality
  Widget _buildImageViewer() {
    return Center(
      child: PinchZoom(
        maxScale: 5.0,
        child: CachedNetworkImage(
          imageUrl: widget.fileUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CustomCircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a web viewer for PDFs and other document types
  Widget _buildWebViewer() {
    // Using Google Docs Viewer for better compatibility
    final viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.fileUrl)}';

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(viewerUrl),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useHybridComposition: true,
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
          ),
          onLoadStart: (controller, url) {
            setState(() {
              _isLoading = true;
            });
          },
          onLoadStop: (controller, url) {
            setState(() {
              _isLoading = false;
            });
          },
          onReceivedError: (controller, request, error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: CustomCircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomAppBar(
        title: widget.fileName,
        showBackButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fileType == FileType.image
          ? Colors.black
          : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
            ),
            child: _buildFileViewer(),
          ),
          if (_fileType != FileType.image) _buildAppBar(),
          if (_fileType == FileType.image)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Enum to represent different file types
enum FileType {
  image,
  pdf,
  other,
}
