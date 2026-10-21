/// One page of a list endpoint's response, with the paging position.
///
/// [items] are still raw json — each repository maps them to its own model.
class PagedResult {
  final List<dynamic> items;
  final int currentPage;
  final int totalPage;

  const PagedResult({
    required this.items,
    required this.currentPage,
    required this.totalPage,
  });

  bool get hasMore => currentPage < totalPage;
}

/// Reads one page out of whichever shape a list endpoint returned.
///
/// Endpoints here have moved from returning a bare list to returning a
/// paginator (`{current_page, last_page, data: [...]}`) at different times, and
/// casting one shape as the other throws — which is how a screen ends up
/// showing an error instead of its list. Both are accepted so a change on
/// either side stays harmless.
///
/// A bare list is treated as a single complete page, which is what it is.
PagedResult readPagedData(dynamic data) {
  final isPaginated = data is Map;

  return PagedResult(
    items: (isPaginated ? (data['data'] ?? []) : (data ?? [])) as List,
    currentPage: isPaginated ? (data['current_page'] as int? ?? 1) : 1,
    totalPage: isPaginated ? (data['last_page'] as int? ?? 1) : 1,
  );
}
