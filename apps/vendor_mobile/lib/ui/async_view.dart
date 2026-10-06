import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../data/vendor_repository.dart';
import 'shell.dart';
import 'widgets.dart';

/// Loads once per key and renders explicit loading / error / blocked / data
/// states. Stale responses are discarded when a newer load supersedes them.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.emptyMessage,
    this.isEmpty,
    this.loading,
    this.live = false,
  });

  /// Operational lists: reload silently (keeping the current data on
  /// screen) when the app returns to the foreground or an operational
  /// notification arrives ([AppState.liveTick]). Off for forms, so unsaved
  /// edits are never replaced.
  final bool live;

  /// Page-shaped placeholder shown while loading; a heading and rows by
  /// default.
  final Widget? loading;

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  int _generation = 0;

  ValueNotifier<int>? _tick;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.live) return;
    final tick = AppScope.maybeRead(context)?.liveTick;
    if (identical(tick, _tick)) return;
    _tick?.removeListener(_load);
    _tick = tick?..addListener(_load);
  }

  @override
  void dispose() {
    _tick?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (mounted) setState(() => _loading = true);
    try {
      final value = await widget.load();
      if (!mounted || generation != _generation) return; // stale response
      setState(() {
        _data = value;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return widget.loading ?? const SkeletonPage();
    }
    if (_error != null && _data == null) {
      final err = _error;
      // Page-level states sit centred in the free content area like every
      // other empty state (PageBody's rule), never pinned to the top.
      if (err is RepositoryError && err.isMissingContract) {
        return PageBody(children: [StateBlock.blocked(err.message)]);
      }
      return PageBody(children: [StateBlock.error('$err', onRetry: _load)]);
    }
    final data = _data as T;
    if (widget.isEmpty?.call(data) == true && widget.emptyMessage != null) {
      return PageBody(children: [StateBlock.empty(widget.emptyMessage!)]);
    }
    return widget.builder(context, data, _load);
  }
}
