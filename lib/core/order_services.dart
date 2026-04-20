List<String> orderServiceList(Map<dynamic, dynamic> order) {
  final fromList =
      (order['services'] as List?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];
  if (fromList.isNotEmpty) {
    return fromList;
  }

  final raw = order['service']?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return const <String>[];
  }

  if (!raw.contains(',')) {
    return <String>[raw];
  }

  final fromLegacySplit = raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return fromLegacySplit.isEmpty ? <String>[raw] : fromLegacySplit;
}

String orderServicesSummary(
  Map<dynamic, dynamic> order, {
  int maxItems = 1,
  String emptyFallback = '-',
}) {
  final services = orderServiceList(order);
  if (services.isEmpty) {
    return emptyFallback;
  }

  if (services.length <= maxItems) {
    return services.join(', ');
  }

  final head = services.take(maxItems).join(', ');
  final tailCount = services.length - maxItems;
  return '$head +$tailCount';
}

String orderServicesFull(
  Map<dynamic, dynamic> order, {
  String emptyFallback = '-',
}) {
  final services = orderServiceList(order);
  if (services.isEmpty) {
    return emptyFallback;
  }
  return services.join(', ');
}
