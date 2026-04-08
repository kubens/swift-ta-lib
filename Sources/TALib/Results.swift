/// Result returned by an indicator that produces a single floating-point output series.
///
/// TA-Lib often omits the leading elements for which a calculation is not yet possible.
/// `beginIndex` indicates the first index in the original input that corresponds to the
/// first item in `values`.
public struct IndicatorResult: Sendable, Equatable {

  /// Calculated indicator values trimmed to the number of produced elements.
  public let values: [Double]

  /// Index in the original input series where `values.first` belongs.
  public let beginIndex: Int
}

/// Result returned by an indicator that produces a single integer output series.
///
/// This is used mainly by pattern-recognition functions, where values commonly encode
/// bearish, neutral, or bullish signals.
public struct IndicatorIntResult: Sendable, Equatable {

  /// Calculated integer indicator values.
  public let values: [Int32]

  /// Index in the original input series where `values.first` belongs.
  public let beginIndex: Int
}
