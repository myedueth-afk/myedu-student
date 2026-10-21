/// A short-lived link that opens one student's live bus map on the web
/// tracking page, without that page needing a web login.
///
/// The token that authorises the page travels inside [url]'s fragment and is
/// deliberately not modelled here. The app's whole job is to hand the finished
/// URL to a WebView; nothing on this side should ever hold the token, send it,
/// or store it, and leaving it unparsed is what keeps that true.
class LiveTrackingLink {
  final String url;

  /// When the link stops working. The backend ties this to the end of the
  /// trip, so it is usually minutes away rather than hours — long enough for
  /// the ride, short enough that a leaked URL is worth little.
  final DateTime? expiresAt;

  /// The trip the link is pinned to, or null when the bus has not started yet.
  /// A link is still issued in that case: the page opens and waits for the
  /// bus rather than refusing.
  final int? tripId;

  const LiveTrackingLink({
    required this.url,
    this.expiresAt,
    this.tripId,
  });

  factory LiveTrackingLink.fromJson(Map<String, dynamic> json) {
    return LiveTrackingLink(
      url: (json['url'] ?? "").toString(),
      // The backend sends ISO-8601 with an offset; anything else parses to
      // null, which reads as "never lapses" and is the safe way to be wrong —
      // the page still shows its own expiry notice if the link does lapse.
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? "").toString())?.toLocal(),
      tripId: int.tryParse((json['trip_id'] ?? "").toString()),
    );
  }

  bool get isUsable => url.isNotEmpty;

  /// Replaced this long before [expiresAt]. A page opened seconds before the
  /// link lapses would show its expiry notice almost immediately, which reads
  /// as a broken screen rather than as an expired link.
  static const Duration _renewalMargin = Duration(minutes: 1);

  bool get needsRenewal {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return !DateTime.now().isBefore(expiry.subtract(_renewalMargin));
  }

  /// How long until this link should be replaced, or null when it never
  /// lapses. [Duration.zero] means it is already due.
  Duration? get timeUntilRenewal {
    final expiry = expiresAt;
    if (expiry == null) return null;
    final remaining =
        expiry.subtract(_renewalMargin).difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
