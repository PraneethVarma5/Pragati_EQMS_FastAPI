// import 'dart:math' as math;
//
// /// Replicates Excel's BETAINV(probability, alpha, beta) and the two
// /// confidence-limit formulas built on top of it in
// /// `Statistical Report!B13:G13` (95% UCL) and `!B15:G15` (95% LCL).
// ///
// /// Excel's BETAINV is the inverse of the (regularized) incomplete beta
// /// function. There's no built-in in Dart, so this file implements it the
// /// same way Excel/most stats libraries do internally:
// ///   1. `_logGamma`      – Lanczos approximation of ln(Γ(x))
// ///   2. `_betaContinuedFraction` – continued-fraction expansion (Numerical
// ///      Recipes' `betacf`), used to evaluate the regularized incomplete
// ///      beta function I_x(a, b)
// ///   3. `regularizedIncompleteBeta` – I_x(a, b), Excel's BETADIST(x,a,b)
// ///   4. `betaInv` – inverts (3) via bisection, i.e. Excel's BETAINV
// class BetaStat {
//   BetaStat._();
//
//   // ---------------------------------------------------------------------
//   // ln(Gamma(x)) – Lanczos approximation (g=7, n=9), standard coefficients.
//   // Accurate to ~15 significant digits for x > 0.
//   // ---------------------------------------------------------------------
//   static const List<double> _lanczosCoefficients = [
//     0.99999999999980993,
//     676.5203681218851,
//     -1259.1392167224028,
//     771.32342877765313,
//     -176.61502916214059,
//     12.507343278686905,
//     -0.13857109526572012,
//     9.9843695780195716e-6,
//     1.5056327351493116e-7,
//   ];
//
//   static double _logGamma(double x) {
//     if (x < 0.5) {
//       // Reflection formula: Γ(x)Γ(1-x) = π / sin(πx)
//       return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1 - x);
//     }
//
//     x -= 1;
//     double a = _lanczosCoefficients[0];
//     final double t = x + 7.5; // g + 0.5, g = 7
//
//     for (int i = 1; i < 9; i++) {
//       a += _lanczosCoefficients[i] / (x + i);
//     }
//
//     return 0.5 * math.log(2 * math.pi) +
//         (x + 0.5) * math.log(t) -
//         t +
//         math.log(a);
//   }
//
//   // ---------------------------------------------------------------------
//   // Continued-fraction expansion used inside the regularized incomplete
//   // beta function (Numerical Recipes `betacf`).
//   // ---------------------------------------------------------------------
//   static double _betaContinuedFraction(double x, double a, double b) {
//     const int maxIterations = 200;
//     const double epsilon = 3e-14;
//     const double tiny = 1e-300;
//
//     final double qab = a + b;
//     final double qap = a + 1.0;
//     final double qam = a - 1.0;
//
//     double c = 1.0;
//     double d = 1.0 - qab * x / qap;
//     if (d.abs() < tiny) d = tiny;
//     d = 1.0 / d;
//     double h = d;
//
//     for (int m = 1; m <= maxIterations; m++) {
//       final int m2 = 2 * m;
//
//       double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
//       d = 1.0 + aa * d;
//       if (d.abs() < tiny) d = tiny;
//       c = 1.0 + aa / c;
//       if (c.abs() < tiny) c = tiny;
//       d = 1.0 / d;
//       h *= d * c;
//
//       aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
//       d = 1.0 + aa * d;
//       if (d.abs() < tiny) d = tiny;
//       c = 1.0 + aa / c;
//       if (c.abs() < tiny) c = tiny;
//       d = 1.0 / d;
//       final double delta = d * c;
//       h *= delta;
//
//       if ((delta - 1.0).abs() < epsilon) break;
//     }
//
//     return h;
//   }
//
//   /// I_x(a, b) — the regularized incomplete beta function.
//   /// This is Excel's BETADIST(x, a, b) with the default cumulative bounds
//   /// (A=0, B=1). Domain: 0 <= x <= 1, a > 0, b > 0.
//   static double regularizedIncompleteBeta(double x, double a, double b) {
//     if (x <= 0) return 0.0;
//     if (x >= 1) return 1.0;
//
//     final double logBeta = _logGamma(a + b) -
//         _logGamma(a) -
//         _logGamma(b) +
//         a * math.log(x) +
//         b * math.log(1 - x);
//     final double front = math.exp(logBeta);
//
//     if (x < (a + 1.0) / (a + b + 2.0)) {
//       return front * _betaContinuedFraction(x, a, b) / a;
//     } else {
//       return 1.0 - front * _betaContinuedFraction(1 - x, b, a) / b;
//     }
//   }
//
//   /// Excel's BETAINV(probability, alpha, beta) for the default bounds
//   /// (A=0, B=1) that the workbook uses everywhere.
//   ///
//   /// Finds x such that regularizedIncompleteBeta(x, a, b) == probability,
//   /// via bisection (the CDF is monotonic on [0, 1], so this is safe and
//   /// numerically stable — matches Excel to ~1e-10 or better).
//   static double betaInv(
//       double probability,
//       double alpha,
//       double beta, {
//         double tolerance = 1e-12,
//         int maxIterations = 200,
//       }) {
//     if (probability <= 0) return 0.0;
//     if (probability >= 1) return 1.0;
//     if (alpha <= 0 || beta <= 0) {
//       throw ArgumentError('BETAINV: alpha and beta must both be > 0');
//     }
//
//     double low = 0.0;
//     double high = 1.0;
//     double mid = 0.5;
//
//     for (int i = 0; i < maxIterations; i++) {
//       mid = (low + high) / 2;
//       final double value = regularizedIncompleteBeta(mid, alpha, beta);
//
//       if ((value - probability).abs() < tolerance) {
//         return mid;
//       }
//
//       if (value < probability) {
//         low = mid;
//       } else {
//         high = mid;
//       }
//     }
//
//     return mid;
//   }
//
//   // ---------------------------------------------------------------------
//   // The two confidence-limit formulas actually used in the workbook.
//   // These replicate, cell for cell, e.g. Statistical Report!B13 and !B15:
//   //
//   // 95% UCL  =IF(matched=0, 1-10^(LOG10((1-0.95)/2)/total),
//   //              IF(total=matched, 1,
//   //                 BETAINV((1+0.95)/2, matched+1, total-matched)))
//   //
//   // 95% LCL  =IF(total=matched, 10^(LOG10((1-0.95)/2)/total),
//   //              IF(matched=0, 0,
//   //                 1-BETAINV((1+0.95)/2, total+1-matched, matched)))
//   //
//   // `confidence` defaults to 0.95 to match every instance in this workbook
//   // (Statistical Report rows 13/15, 24/26, 31/33).
//   // ---------------------------------------------------------------------
//
//   static double ucl95(int matched, int total, {double confidence = 0.95}) {
//     if (total <= 0) return 0.0;
//
//     if (matched == 0) {
//       final double alphaTail = (1 - confidence) / 2;
//       return 1 - math.pow(10, _log10(alphaTail) / total).toDouble();
//     }
//
//     if (total == matched) {
//       return 1.0;
//     }
//
//     return betaInv(
//       (1 + confidence) / 2,
//       (matched + 1).toDouble(),
//       (total - matched).toDouble(),
//     );
//   }
//
//   static double lcl95(int matched, int total, {double confidence = 0.95}) {
//     if (total <= 0) return 0.0;
//
//     if (total == matched) {
//       final double alphaTail = (1 - confidence) / 2;
//       return math.pow(10, _log10(alphaTail) / total).toDouble();
//     }
//
//     if (matched == 0) {
//       return 0.0;
//     }
//
//     return 1 -
//         betaInv(
//           (1 + confidence) / 2,
//           (total + 1 - matched).toDouble(),
//           matched.toDouble(),
//         );
//   }
//
//   static double _log10(double x) => math.log(x) / math.ln10;
// }



import 'dart:math' as math;

/// Replicates Excel's BETAINV(probability, alpha, beta) and the two
/// confidence-limit formulas built on top of it in
/// `Statistical Report!B13:G13` (95% UCL) and `!B15:G15` (95% LCL).
///
/// Excel's BETAINV is the inverse of the (regularized) incomplete beta
/// function. There's no built-in in Dart, so this file implements it the
/// same way Excel/most stats libraries do internally:
///   1. `_logGamma`      – Lanczos approximation of ln(Γ(x))
///   2. `_betaContinuedFraction` – continued-fraction expansion (Numerical
///      Recipes' `betacf`), used to evaluate the regularized incomplete
///      beta function I_x(a, b)
///   3. `regularizedIncompleteBeta` – I_x(a, b), Excel's BETADIST(x,a,b)
///   4. `betaInv` – inverts (3) via bisection, i.e. Excel's BETAINV
class BetaStat {
  BetaStat._();

  // ---------------------------------------------------------------------
  // ln(Gamma(x)) – Lanczos approximation (g=7, n=9), standard coefficients.
  // Accurate to ~15 significant digits for x > 0.
  // ---------------------------------------------------------------------
  static const List<double> _lanczosCoefficients = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];

  static double _logGamma(double x) {
    if (x < 0.5) {
      // Reflection formula: Γ(x)Γ(1-x) = π / sin(πx)
      return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1 - x);
    }

    x -= 1;
    double a = _lanczosCoefficients[0];
    final double t = x + 7.5; // g + 0.5, g = 7

    for (int i = 1; i < 9; i++) {
      a += _lanczosCoefficients[i] / (x + i);
    }

    return 0.5 * math.log(2 * math.pi) +
        (x + 0.5) * math.log(t) -
        t +
        math.log(a);
  }

  // ---------------------------------------------------------------------
  // Continued-fraction expansion used inside the regularized incomplete
  // beta function (Numerical Recipes `betacf`).
  // ---------------------------------------------------------------------
  static double _betaContinuedFraction(double x, double a, double b) {
    const int maxIterations = 200;
    const double epsilon = 3e-14;
    const double tiny = 1e-300;

    final double qab = a + b;
    final double qap = a + 1.0;
    final double qam = a - 1.0;

    double c = 1.0;
    double d = 1.0 - qab * x / qap;
    if (d.abs() < tiny) d = tiny;
    d = 1.0 / d;
    double h = d;

    for (int m = 1; m <= maxIterations; m++) {
      final int m2 = 2 * m;

      double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
      d = 1.0 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1.0 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1.0 / d;
      h *= d * c;

      aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
      d = 1.0 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1.0 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1.0 / d;
      final double delta = d * c;
      h *= delta;

      if ((delta - 1.0).abs() < epsilon) break;
    }

    return h;
  }

  /// I_x(a, b) — the regularized incomplete beta function.
  /// This is Excel's BETADIST(x, a, b) with the default cumulative bounds
  /// (A=0, B=1). Domain: 0 <= x <= 1, a > 0, b > 0.
  static double regularizedIncompleteBeta(double x, double a, double b) {
    if (x <= 0) return 0.0;
    if (x >= 1) return 1.0;

    final double logBeta = _logGamma(a + b) -
        _logGamma(a) -
        _logGamma(b) +
        a * math.log(x) +
        b * math.log(1 - x);
    final double front = math.exp(logBeta);

    if (x < (a + 1.0) / (a + b + 2.0)) {
      return front * _betaContinuedFraction(x, a, b) / a;
    } else {
      return 1.0 - front * _betaContinuedFraction(1 - x, b, a) / b;
    }
  }

  /// Excel's BETAINV(probability, alpha, beta) for the default bounds
  /// (A=0, B=1) that the workbook uses everywhere.
  ///
  /// Finds x such that regularizedIncompleteBeta(x, a, b) == probability,
  /// via bisection (the CDF is monotonic on [0, 1], so this is safe and
  /// numerically stable — matches Excel to ~1e-10 or better).
  static double betaInv(
      double probability,
      double alpha,
      double beta, {
        double tolerance = 1e-12,
        int maxIterations = 200,
      }) {
    if (probability <= 0) return 0.0;
    if (probability >= 1) return 1.0;
    if (alpha <= 0 || beta <= 0) {
      throw ArgumentError('BETAINV: alpha and beta must both be > 0');
    }

    double low = 0.0;
    double high = 1.0;
    double mid = 0.5;

    for (int i = 0; i < maxIterations; i++) {
      mid = (low + high) / 2;
      final double value = regularizedIncompleteBeta(mid, alpha, beta);

      if ((value - probability).abs() < tolerance) {
        return mid;
      }

      if (value < probability) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return mid;
  }

  // ---------------------------------------------------------------------
  // The two confidence-limit formulas actually used in the workbook.
  // These replicate, cell for cell, e.g. Statistical Report!B13 and !B15:
  //
  // 95% UCL  =IF(matched=0, 1-10^(LOG10((1-0.95)/2)/total),
  //              IF(total=matched, 1,
  //                 BETAINV((1+0.95)/2, matched+1, total-matched)))
  //
  // 95% LCL  =IF(total=matched, 10^(LOG10((1-0.95)/2)/total),
  //              IF(matched=0, 0,
  //                 1-BETAINV((1+0.95)/2, total+1-matched, matched)))
  //
  // `confidence` defaults to 0.95 to match every instance in this workbook
  // (Statistical Report rows 13/15, 24/26, 31/33).
  // ---------------------------------------------------------------------

  static double ucl95(int matched, int total, {double confidence = 0.95}) {
    if (total <= 0) return 0.0;

    if (matched == 0) {
      final double alphaTail = (1 - confidence) / 2;
      return 1 - math.pow(10, _log10(alphaTail) / total).toDouble();
    }

    if (total == matched) {
      return 1.0;
    }

    return betaInv(
      (1 + confidence) / 2,
      (matched + 1).toDouble(),
      (total - matched).toDouble(),
    );
  }

  static double lcl95(int matched, int total, {double confidence = 0.95}) {
    if (total <= 0) return 0.0;

    if (total == matched) {
      final double alphaTail = (1 - confidence) / 2;
      return math.pow(10, _log10(alphaTail) / total).toDouble();
    }

    if (matched == 0) {
      return 0.0;
    }

    return 1 -
        betaInv(
          (1 + confidence) / 2,
          (total + 1 - matched).toDouble(),
          matched.toDouble(),
        );
  }

  static double _log10(double x) => math.log(x) / math.ln10;
}