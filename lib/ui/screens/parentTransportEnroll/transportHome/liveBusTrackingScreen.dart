import 'dart:async';

import 'package:eschool/cubits/liveTrackingLinkCubit.dart';
import 'package:eschool/data/models/liveTrackingLink.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

/// Shows one student's bus on the web live-tracking page, inside the app.
///
/// The page itself needs an identity, and a WebView has no web login to take
/// one from. So the screen asks the backend for a link that already carries a
/// scoped, short-lived token, and opens that. Everything after the first load
/// — polling, the map, the ETA — belongs to the page, not to the app.
///
/// Two consequences shape the code below:
/// * The token rides in the URL's fragment, and the page clears it from the
///   address bar once read. Reloading would therefore load a page with no
///   token, so every retry and every renewal mints a fresh link instead.
/// * Links expire with the trip. A screen left open past that would silently
///   turn into the page's expiry notice, so the link is replaced a minute
///   before it lapses and again whenever the app comes back to the foreground.
class LiveBusTrackingScreen extends StatefulWidget {
  /// The student being tracked — the selected child, when a parent is signed
  /// in. The backend refuses ids the caller may not track.
  final int userId;

  /// Pins the link to one trip. Null tracks whichever trip is running, which
  /// is what the transport home card wants.
  final int? tripId;

  const LiveBusTrackingScreen({
    super.key,
    required this.userId,
    this.tripId,
  });

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    final int userId = (arguments?['userId'] as int?) ??
        AuthRepository.getStudentDetails().id ??
        0;

    return BlocProvider(
      create: (context) => LiveTrackingLinkCubit(),
      child: LiveBusTrackingScreen(
        userId: userId,
        tripId: arguments?['tripId'] as int?,
      ),
    );
  }

  @override
  State<LiveBusTrackingScreen> createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen>
    with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;

  /// The link currently on screen. Null until the first one arrives, which is
  /// what separates "still opening" from "map is up and something failed".
  LiveTrackingLink? _link;

  bool _isPageLoading = true;
  bool _hasPageError = false;

  /// Guards the one automatic recovery from the web app's login redirect.
  bool _hasRetriedLoginRedirect = false;

  Timer? _renewalTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createLink();
  }

  @override
  void dispose() {
    _renewalTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // A backgrounded app gets its timers frozen, so a phone left in a pocket
    // through the whole ride comes back to a link that lapsed without anything
    // firing. Checking on resume is what closes that gap.
    if (_link?.needsRenewal ?? false) {
      _createLink(isRenewal: true);
    }
  }

  void _createLink({bool isRenewal = false}) {
    if (widget.userId <= 0) return;

    if (!isRenewal && mounted) {
      setState(() {
        _hasPageError = false;
      });
    }

    context.read<LiveTrackingLinkCubit>().createLink(
          userId: widget.userId,
          tripId: widget.tripId,
          isRenewal: isRenewal,
        );
  }

  void _onLinkReady(LiveTrackingLink link) {
    _scheduleRenewal(link);

    final controller = _webViewController;
    setState(() {
      _link = link;
      _hasPageError = false;
      _isPageLoading = true;
    });

    // On the first link the WebView does not exist yet and picks the URL up as
    // its initial request; afterwards it is already alive and only needs to be
    // pointed at the new one.
    controller?.loadUrl(urlRequest: URLRequest(url: WebUri(link.url)));
  }

  /// Shortest gap this screen will wait before replacing a link.
  ///
  /// A backend that hands back an already-lapsed link would otherwise have
  /// this screen minting in a tight loop. Below this the timer is simply not
  /// set: the resume check and the page's own expiry notice still cover it.
  static const Duration _minimumRenewalDelay = Duration(seconds: 30);

  void _scheduleRenewal(LiveTrackingLink link) {
    _renewalTimer?.cancel();

    final timeUntilRenewal = link.timeUntilRenewal;
    if (timeUntilRenewal == null || timeUntilRenewal < _minimumRenewalDelay) {
      return;
    }

    _renewalTimer = Timer(timeUntilRenewal, () {
      if (mounted) _createLink(isRenewal: true);
    });
  }

  /// Keeps the WebView on the tracking page.
  ///
  /// The page has no outbound links today, so this is a guard rather than a
  /// feature: it stops a stray navigation from turning the screen into a
  /// general browser, or into a web login the person here cannot complete.
  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    // Sub-frames carry the Google Maps embed. Restricting those would blank
    // the map, which is the one thing the screen exists to show.
    if (action.isForMainFrame != true) return NavigationActionPolicy.ALLOW;

    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;

    // Custom schemes are how a page hands off to another app — a store
    // listing, a dialler. Nothing on a tracking page should do that.
    if (url.scheme != "http" && url.scheme != "https") {
      return NavigationActionPolicy.CANCEL;
    }

    // The web app sends expired sessions to its own login screen. In a WebView
    // that is a dead end, so it is treated as the expiry it actually is and
    // answered with a fresh link — but only once. A page that redirects on
    // every load would otherwise mint links until the rate limit bites, so the
    // second attempt hands the decision back to the person instead.
    if (url.path.contains("/auth/login")) {
      if (_hasRetriedLoginRedirect) {
        _onPageFailed();
      } else {
        _hasRetriedLoginRedirect = true;
        _createLink(isRenewal: true);
      }
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  void _onPageFailed() {
    if (!mounted) return;
    setState(() {
      _isPageLoading = false;
      _hasPageError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CustomAppBar(title: liveTrackingKey, showBackButton: true),
          Expanded(
            child: BlocConsumer<LiveTrackingLinkCubit, LiveTrackingLinkState>(
              listener: (context, state) {
                if (state is LiveTrackingLinkFetchSuccess) {
                  _onLinkReady(state.link);
                  return;
                }

                // A renewal that fails behind a map already on screen must not
                // replace it: the page keeps showing the last known position,
                // and the person is told rather than shown an error screen.
                if (state is LiveTrackingLinkFetchFailure && _link != null) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: Utils.getErrorMessageFromErrorCode(
                      context,
                      state.errorMessage,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  );
                }
              },
              builder: (context, state) {
                if (widget.userId <= 0) {
                  return ErrorContainer(
                    errorMessageCode:
                        ErrorMessageKeysAndCode.defaultErrorMessageCode,
                    showRetryButton: false,
                  );
                }

                // Nothing has loaded yet, so this is the whole screen.
                if (_link == null) {
                  if (state is LiveTrackingLinkFetchFailure) {
                    return ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: _createLink,
                    );
                  }
                  return const Center(child: CustomCircularProgressIndicator());
                }

                return _buildWebView(_link!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(LiveTrackingLink link) {
    return Stack(
      children: [
        InAppWebView(
          key: const ValueKey("liveBusTrackingWebView"),
          initialUrlRequest: URLRequest(url: WebUri(link.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useHybridComposition: true,
            useShouldOverrideUrlLoading: true,
            supportZoom: false,
            // The link is meant to live no longer than the trip. Keeping it
            // out of any persistent store is what makes that true on the
            // device as well as on the server.
            incognito: true,
            clearCache: true,
          ),
          onWebViewCreated: (controller) => _webViewController = controller,
          onLoadStart: (controller, url) {
            if (!mounted) return;
            setState(() {
              _isPageLoading = true;
              _hasPageError = false;
            });
          },
          onLoadStop: (controller, url) {
            if (!mounted) return;
            setState(() => _isPageLoading = false);
          },
          shouldOverrideUrlLoading: _handleNavigation,
          onReceivedError: (controller, request, error) {
            if (request.isForMainFrame ?? false) _onPageFailed();
          },
          onReceivedHttpError: (controller, request, response) {
            if (request.isForMainFrame ?? false) _onPageFailed();
          },
        ),
        if (_hasPageError)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ErrorContainer(
              errorMessageCode: unableToOpenLiveTrackingKey,
              onTapRetry: _createLink,
            ),
          )
        else if (_isPageLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: CustomCircularProgressIndicator()),
          ),
      ],
    );
  }
}
