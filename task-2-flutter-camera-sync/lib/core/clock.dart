/// Source of "now". Injected so time-dependent code is deterministic in tests.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();
