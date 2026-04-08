import TALib
import Testing

@Suite("TA-Lib Indicators")
struct IndicatorTests {

  // MARK: - SMA

  @Test("SMA with period 3 on known data")
  func smaBasic() throws {
    // Input: [1,2,3,4,5]
    // SMA(3): [2.0, 3.0, 4.0] starting at index 2
    let result = try sma([1, 2, 3, 4, 5], timePeriod: 3)
    #expect(result.beginIndex == 2)
    #expect(result.values.count == 3)
    #expect(result.values[0] == 2.0)
    #expect(result.values[1] == 3.0)
    #expect(result.values[2] == 4.0)
  }

  @Test("SMA with period equal to input length")
  func smaFullPeriod() throws {
    let result = try sma([10, 20, 30], timePeriod: 3)
    #expect(result.values.count == 1)
    #expect(result.values[0] == 20.0)
    #expect(result.beginIndex == 2)
  }

  @Test("SMA period larger than input returns empty")
  func smaPeriodLargerThanInput() throws {
    let result = try sma([1, 2], timePeriod: 5)
    #expect(result.values.isEmpty)
  }

  // MARK: - RSI

  @Test("RSI output count is correct for period 14")
  func rsiOutputCount() throws {
    // RSI(14) needs at least 15 data points; first output is at index 14
    let prices = (1...30).map { Double($0) }
    let result = try rsi(prices, timePeriod: 14)
    #expect(result.beginIndex == 14)
    #expect(result.values.count == 16)
  }

  @Test("RSI values are in 0–100 range")
  func rsiRange() throws {
    let prices: [Double] = [
      44.34, 44.09, 44.15, 43.61, 44.33, 44.83, 45.10, 45.15,
      43.61, 44.33, 44.83, 45.10, 45.15, 45.45, 45.82, 46.08,
      45.66, 46.03, 46.41, 46.22,
    ]
    let result = try rsi(prices, timePeriod: 14)
    for value in result.values {
      #expect(value >= 0.0 && value <= 100.0)
    }
  }

  // MARK: - MACD

  @Test("MACD returns three output series")
  func macdOutputs() throws {
    let prices: [Double] = stride(from: 1.0, through: 40.0, by: 1.0).map { $0 }
    let result = try macd(prices, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)
    // MACD line starts at index 25 (slowPeriod - 1), signal adds 8 more → 33
    #expect(result.mACD.beginIndex == 33)
    #expect(result.mACD.values.count == result.mACDSignal.values.count)
    #expect(result.mACD.values.count == result.mACDHist.values.count)
  }

  @Test("MACD histogram equals MACD line minus signal")
  func macdHistogramConsistency() throws {
    let prices: [Double] = stride(from: 1.0, through: 50.0, by: 1.0).map { $0 }
    let result = try macd(prices, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)
    for i in result.mACD.values.indices {
      let expected = result.mACD.values[i] - result.mACDSignal.values[i]
      #expect(abs(result.mACDHist.values[i] - expected) < 1e-10)
    }
  }

  // MARK: - EMA

  @Test("EMA output count matches expectation for period 3")
  func emaOutputCount() throws {
    // EMA(3) on 5 elements: first valid at index 2, so 3 output values
    let prices: [Double] = [10, 20, 30, 40, 50]
    let result = try ema(prices, timePeriod: 3)
    #expect(result.beginIndex == 2)
    #expect(result.values.count == 3)
  }

  @Test("EMA with invalid period throws badParam")
  func emaInvalidPeriod() throws {
    do {
      _ = try ema([10, 20, 30], timePeriod: 1)
      Issue.record("Expected TAError to be thrown")
    } catch {
      #expect(error.code == .badParam)
    }
  }

  // MARK: - Bollinger Bands

  @Test("Bollinger Bands: upper >= middle >= lower")
  func bollingerBandsOrdering() throws {
    let prices: [Double] = [
      20, 21, 22, 21, 20, 19, 20, 21, 22, 23,
      22, 21, 20, 19, 18, 19, 20, 21, 22, 23,
    ]
    let result = try bbands(prices, timePeriod: 5)
    for i in result.realUpperBand.values.indices {
      #expect(result.realUpperBand.values[i] >= result.realMiddleBand.values[i])
      #expect(result.realMiddleBand.values[i] >= result.realLowerBand.values[i])
    }
  }

  @Test("Bollinger Bands beginIndex matches SMA beginIndex")
  func bollingerBandsBeginIndex() throws {
    let prices: [Double] = stride(from: 1.0, through: 20.0, by: 1.0).map { $0 }
    let bb = try bbands(prices, timePeriod: 5)
    let s = try sma(prices, timePeriod: 5)
    #expect(bb.realUpperBand.beginIndex == s.beginIndex)
  }
}
