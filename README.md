# swift-ta-lib

Swift wrapper for [TA-Lib](https://ta-lib.org) (Technical Analysis Library) with **161 auto-generated indicator functions**, Swift 6 concurrency safety, and typed errors.

## Features

- **Code generation** -- Swift wrappers are generated at build time from `ta_func_api.xml` via an SPM build plugin. No manual maintenance needed.
- **Swift 6 strict concurrency** -- all public types are `Sendable`.
- **Typed throws** -- functions throw `TAError` with specific error codes.
- **Full TA-Lib coverage** -- 161 indicators including moving averages, oscillators, volume indicators, candlestick patterns, and more.

## Requirements

- Swift 6+
- iOS 12+, macOS 10.13+, watchOS 4+, tvOS 12+, visionOS 1+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kubens/swift-ta-lib.git", from: "1.0.0"),
]
```

Then add `TALib` to your target dependencies:

```swift
.target(name: "YourTarget", dependencies: [
    .product(name: "TALib", package: "swift-ta-lib")
])
```

## Usage

Initialize the underlying TA-Lib runtime before calling indicator functions:

```swift
import TALib

try TA.initialize()
defer { try? TA.shutdown() }
```

`TA.initialize()` should typically be called once during application or subsystem startup. Call `TA.shutdown()` when indicator calculations are no longer needed.

All indicators are free functions in the `TALib` module:

```swift
import TALib

try TA.initialize()
defer { try? TA.shutdown() }

// Simple Moving Average
let prices: [Double] = [1, 2, 3, 4, 5]
let result = try sma(prices, timePeriod: 3)
// result.values    -> [2.0, 3.0, 4.0]
// result.beginIndex -> 2

// RSI
let rsiResult = try rsi(prices, timePeriod: 14)
// rsiResult.values are in 0...100

// MACD (returns named tuple with multiple outputs)
let macdResult = try macd(prices, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)
// macdResult.mACD, macdResult.mACDSignal, macdResult.mACDHist

// Bollinger Bands
let bb = try bbands(prices, timePeriod: 5)
// bb.realUpperBand, bb.realMiddleBand, bb.realLowerBand

// Candlestick patterns (return Int32 values: -100, 0, or 100)
let hammer = try cdlHammer(open: opens, high: highs, low: lows, close: closes)
```

### Return Types

- **`IndicatorResult`** -- single `[Double]` output with `values` and `beginIndex`
- **`IndicatorIntResult`** -- single `[Int32]` output (candlestick patterns)
- **Named tuples** -- indicators with multiple outputs (e.g., MACD, Bollinger Bands)

`beginIndex` indicates where in the original input array the output starts. For example, SMA with period 3 on 5 elements starts at index 2.

### Error Handling

```swift
do {
    try TA.initialize()
    defer { try? TA.shutdown() }

    let result = try ema(prices, timePeriod: 1)
} catch {
    // error is TAError with .code property
    print(error.code) // .badParam
}
```

## License

TA-Lib is distributed under a BSD-style license. See `Sources/ta-lib/LICENSE` for details.
