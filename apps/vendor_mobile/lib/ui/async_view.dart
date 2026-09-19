import 'package:flutter/material.dart';

import '../data/vendor_repository.dart';
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
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
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

  @override
  void initState() {
    super.initState();
    _load();
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
    if (_loading && _data == null) return const StateBlock.loading();
    if (_error != null && _data == null) {
      final err = _error;
      if (err is RepositoryError && err.isMissingContract) {
        return StateBlock.blocked(err.message);
      }
      return StateBlock.error('$err', onRetry: _load);
    }
    final data = _data as T;
    if (widget.isEmpty?.call(data) == true && widget.emptyMessage != null) {
      return StateBlock.empty(widget.emptyMessage!);
    }
    return widget.builder(context, data, _load);
  }
}
