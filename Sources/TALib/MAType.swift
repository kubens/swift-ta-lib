import ta_lib

/// Moving-average algorithm used by TA-Lib functions that accept a MA type.
///
/// The cases map directly to `TA_MAType` values from the C library.
public enum MAType: Int32, Sendable, CaseIterable {

  /// Simple Moving Average.
  case sma = 0

  /// Exponential Moving Average.
  case ema = 1

  /// Weighted Moving Average.
  case wma = 2

  /// Double Exponential Moving Average.
  case dema = 3

  /// Triple Exponential Moving Average.
  case tema = 4

  /// Triangular Moving Average.
  case trima = 5

  /// Kaufman Adaptive Moving Average.
  case kama = 6

  /// MESA Adaptive Moving Average.
  case mama = 7

  /// Tillson T3 Moving Average.
  case t3 = 8

  var cValue: TA_MAType {
    TA_MAType(rawValue: UInt32(rawValue))
  }
}
