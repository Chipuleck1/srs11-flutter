class BenchmarkResult {
  const BenchmarkResult(this.name, this.withIndexMs, this.withoutIndexMs);

  final String name;
  final double withIndexMs;
  final double withoutIndexMs;

  double get speedup => withIndexMs == 0 ? 0 : withoutIndexMs / withIndexMs;
}
