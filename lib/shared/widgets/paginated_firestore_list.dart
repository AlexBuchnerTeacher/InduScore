import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';

/// Ein generisches Widget für paginierte Listen mit Firestore.
///
/// Unterstützt:
/// - Initiales Laden mit Limit
/// - "Mehr laden" Button
/// - Automatisches Scroll-Loading (optional)
/// - Loading- und Error-States
///
/// Beispiel:
/// ```dart
/// PaginatedFirestoreList<Student>(
///   query: firestore.collection('students').orderBy('lastName'),
///   itemBuilder: (student) => StudentTile(student),
///   fromFirestore: Student.fromFirestore,
///   pageSize: 25,
/// )
/// ```
class PaginatedFirestoreList<T> extends StatefulWidget {
  /// Die Firestore-Query (ohne Limit)
  final Query<Map<String, dynamic>> query;

  /// Funktion zum Konvertieren von Firestore-Dokumenten
  final T Function(DocumentSnapshot<Map<String, dynamic>> doc) fromFirestore;

  /// Widget-Builder für jedes Item
  final Widget Function(T item) itemBuilder;

  /// Anzahl Items pro Seite
  final int pageSize;

  /// Optionaler Header über der Liste
  final Widget? header;

  /// Widget bei leerer Liste
  final Widget? emptyWidget;

  /// Automatisch laden beim Scrollen (Infinite Scroll)
  final bool autoLoadOnScroll;

  /// Scroll-Threshold für Auto-Loading (0.0 - 1.0)
  final double scrollLoadThreshold;

  const PaginatedFirestoreList({
    super.key,
    required this.query,
    required this.fromFirestore,
    required this.itemBuilder,
    this.pageSize = 25,
    this.header,
    this.emptyWidget,
    this.autoLoadOnScroll = false,
    this.scrollLoadThreshold = 0.8,
  });

  @override
  State<PaginatedFirestoreList<T>> createState() =>
      _PaginatedFirestoreListState<T>();
}

class _PaginatedFirestoreListState<T> extends State<PaginatedFirestoreList<T>> {
  final List<T> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.autoLoadOnScroll) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.scrollLoadThreshold;

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await widget.query.limit(widget.pageSize).get();

      setState(() {
        _items.clear();
        _items.addAll(snapshot.docs.map(widget.fromFirestore));
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading || _lastDocument == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await widget.query
          .startAfterDocument(_lastDocument!)
          .limit(widget.pageSize)
          .get();

      setState(() {
        _items.addAll(snapshot.docs.map(widget.fromFirestore));
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return _buildErrorWidget();
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (widget.header != null)
            SliverToBoxAdapter(child: widget.header!),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _items.length) {
                  return widget.itemBuilder(_items[index]);
                }
                return null;
              },
              childCount: _items.length,
            ),
          ),
          if (_hasMore || _isLoading)
            SliverToBoxAdapter(child: _buildLoadMoreWidget()),
          if (_error != null && _items.isNotEmpty)
            SliverToBoxAdapter(child: _buildInlineError()),
        ],
      ),
    );
  }

  Widget _buildLoadMoreWidget() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!widget.autoLoadOnScroll && _hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more),
            label: Text('Mehr laden (${_items.length} geladen)'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: RBSColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RBSColors.redLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: RBSColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text('Fehler: $_error')),
          TextButton(
            onPressed: _loadMore,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Keine Einträge vorhanden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Controller für externe Steuerung der PaginatedFirestoreList
class PaginatedListController {
  VoidCallback? _refreshCallback;

  void attach(VoidCallback refresh) {
    _refreshCallback = refresh;
  }

  void detach() {
    _refreshCallback = null;
  }

  /// Lädt die Liste neu
  void refresh() {
    _refreshCallback?.call();
  }
}
