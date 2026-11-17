import '../../models/audit/audit.dart';
import '../../models/audit/audit_finding.dart';
import '../../models/audit/finding_category.dart';

/// Pure, stateless calculations. No DB or UI concerns in here so it's easy
/// to unit test and to reuse identically between the on-screen tables and
/// the PDF generators.
class AuditCalculationService {
  AuditCalculationService._();

  /// Audit types for which an Audit Score is meaningful. Any other audit
  /// type shows '-' for score instead of a computed number.
  static const scoredAuditTypes = {'Process Audit', 'System Audit'};

  static int criticalCount(List<AuditFinding> findings) =>
      findings.where((f) => f.category == FindingCategory.critical).length;

  static int majorCount(List<AuditFinding> findings) =>
      findings.where((f) => f.category == FindingCategory.major).length;

  static int minorCount(List<AuditFinding> findings) =>
      findings.where((f) => f.category == FindingCategory.minor).length;

  static double auditedHours(Audit audit) => audit.totalTimeTakenHours;

  /// CPH = (Critical + Major findings) / Total Audited Hours
  static double cph({
    required Audit audit,
    required List<AuditFinding> findings,
  }) {
    final hours = auditedHours(audit);
    if (hours <= 0) return 0;
    final numerator = criticalCount(findings) + majorCount(findings);
    return numerator / hours;
  }

  /// Score = 100 - 20*Critical - 5*Major - 2*Minor
  /// Only meaningful for Process Audit / System Audit — see [scoredAuditTypes]
  /// and [isScoreApplicable]. Clamped at 0 as a floor since a negative score
  /// has no real-world meaning.
  static double auditScore({
    required Audit audit,
    required List<AuditFinding> findings,
  }) {
    final raw = 100 -
        (20 * criticalCount(findings)) -
        (5 * majorCount(findings)) -
        (2 * minorCount(findings));
    return raw < 0 ? 0 : raw.toDouble();
  }

  static bool isScoreApplicable(String auditType) =>
      scoredAuditTypes.contains(auditType);

  /// MIL is "closed" once every finding on the audit has overallStatus
  /// == Closed (and it's fine — vacuously true — if there are no findings).
  static bool isMilFullyClosed(List<AuditFinding> findings) {
    return findings.every((f) => f.isClosed);
  }

  static String milStatusLabel({
    required String? milNumber,
    required List<AuditFinding> findings,
  }) {
    if (milNumber == null || milNumber.trim().isEmpty) {
      return 'Not Generated';
    }
    if (findings.isEmpty) return 'Closed';
    return isMilFullyClosed(findings) ? 'Closed' : 'Open';
  }
}
