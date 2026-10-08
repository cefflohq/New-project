import 'dart:js_interop';

/// Flutter Web + the app's own screen stack: without browser history
/// entries, the Android edge-swipe / browser Back leaves the app for the
/// previous page (a blank screen). Every in-app step pushes one entry, and
/// the browser's Back pops the app's stack instead (Founder, 2026-10-01).

@JS('history.pushState')
external void _pushState(JSAny? data, JSString unused);

@JS('history.back')
external void _historyBack();

@JS('window.addEventListener')
external void _addEventListener(JSString type, JSFunction listener);

// The entry is marked as a Flutter entry ({flutter: true}). The Flutter web
// engine treats any other history state as a foreign page and answers its
// popstate with history.go(-1) — each of those popped the app's stack once
// more, so one Back skipped screens (Founder report, 2026-10-08).
void pushBrowserHistoryEntry() =>
    _pushState(<String, Object>{'flutter': true}.jsify(), ''.toJS);

void browserHistoryBack() => _historyBack();

void listenBrowserBack(void Function() onBack) =>
    _addEventListener('popstate'.toJS, ((JSAny _) => onBack()).toJS);

bool get hasBrowserHistory => true;
