class ScanDebugState {
  const ScanDebugState({this.detectCount = 0, this.lastLines = const []});

  final int detectCount;
  final List<String> lastLines;
}
