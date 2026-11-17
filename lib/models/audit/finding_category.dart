/// Severity of a "No" answer on the checklist.
/// Stored in the DB as plain text ('Critical' | 'Major' | 'Minor') so it
/// round-trips cleanly with Supabase without needing a Postgres enum type.
enum FindingCategory {
  critical('Critical'),
  major('Major'),
  minor('Minor');

  final String value;
  const FindingCategory(this.value);

  static FindingCategory? fromString(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    for (final c in FindingCategory.values) {
      if (c.value.toLowerCase() == normalized) return c;
    }
    return null;
  }

  @override
  String toString() => value;
}
