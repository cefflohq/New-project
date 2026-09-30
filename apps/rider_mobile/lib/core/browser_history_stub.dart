/// Non-web builds: the platform back gesture already reaches PopScope.
void pushBrowserHistoryEntry() {}

void browserHistoryBack() {}

void listenBrowserBack(void Function() onBack) {}

bool get hasBrowserHistory => false;
