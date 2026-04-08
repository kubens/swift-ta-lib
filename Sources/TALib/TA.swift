import ta_lib

/// Lifecycle entry points for the underlying TA-Lib runtime.
///
/// Indicator APIs in this package are exposed as free functions in the `TALib` module.
/// This type is only responsible for explicit library initialization and shutdown.
public enum TA {

  /// Initializes the underlying TA-Lib runtime.
  ///
  /// Call this once before invoking indicator functions exposed by the wrapper.
  ///
  /// - Throws: ``TAError`` when TA-Lib fails to initialize.
  public static func initialize() throws(TAError) {
    let ret = TA_Initialize()
    if ret != TA_SUCCESS {
      throw TAError(retCode: ret)
    }
  }

  /// Shuts down the underlying TA-Lib runtime.
  ///
  /// Call this when indicator calculations are no longer needed, typically as part
  /// of application or subsystem teardown.
  ///
  /// - Throws: ``TAError`` when TA-Lib fails to shut down cleanly.
  public static func shutdown() throws(TAError) {
    let ret = TA_Shutdown()
    if ret != TA_SUCCESS {
      throw TAError(retCode: ret)
    }
  }
}
