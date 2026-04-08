import ta_lib

/// Error returned by the Swift wrapper when a TA-Lib call fails.
///
/// The wrapped ``Code`` value mirrors TA-Lib's `TA_RetCode` constants, which makes it
/// possible to handle library-specific failures in a type-safe way.
public struct TAError: Error, Sendable, Equatable {

  /// TA-Lib return codes exposed as a Swift enum.
  public enum Code: Int32, Sendable {

    /// The library was used before `TA.initialize()` completed successfully.
    case libNotInitialize = 1

    /// At least one parameter passed to TA-Lib was invalid.
    case badParam = 2

    /// Memory allocation failed inside the TA-Lib runtime.
    case allocErr = 3

    /// A requested TA-Lib function group could not be found.
    case groupNotFound = 4

    /// A requested TA-Lib function could not be found.
    case funcNotFound = 5

    /// The library reported an invalid function handle.
    case invalidHandle = 6

    /// The parameter holder object was invalid.
    case invalidParamHolder = 7

    /// The parameter holder had an unexpected type.
    case invalidParamHolderType = 8

    /// The parameter metadata for a function was invalid.
    case invalidParamFunction = 9

    /// Not all required input values were initialized.
    case inputNotAllInitialize = 10

    /// Not all required output values were initialized.
    case outputNotAllInitialize = 11

    /// The provided start index was outside the supported range.
    case outOfRangeStartIndex = 12

    /// The provided end index was outside the supported range.
    case outOfRangeEndIndex = 13

    /// A list argument had an invalid type.
    case invalidListType = 14

    /// TA-Lib reported an invalid internal object.
    case badObject = 15

    /// The requested operation is not supported by TA-Lib.
    case notSupported = 16

    /// An unspecified TA-Lib internal error occurred.
    case internalError = 5000

    /// A fallback value used when the return code is unknown to this wrapper.
    case unknownErr = 0xFFFF
  }

  /// Specific TA-Lib error code returned by the failed call.
  public let code: Code

  init(retCode: TA_RetCode) {
    self.code = Code(rawValue: Int32(bitPattern: retCode.rawValue)) ?? .unknownErr
  }
}

// MARK: - CustomStringConvertible
extension TAError: CustomStringConvertible {

  /// A concise textual representation of the TA-Lib failure.
  public var description: String {
    "TAError(\(code))"
  }
}
