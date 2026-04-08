/// Data model representing a single TA-Lib function parsed from `ta_func_api.xml`.
struct TAFunction {
  let abbreviation: String  // e.g. "SMA"
  let camelCaseName: String  // e.g. "Sma" (from XML, used to derive Swift name)
  let shortDescription: String  // e.g. "Simple Moving Average"
  let groupId: String  // e.g. "Overlap Studies"
  let requiredInputs: [InputArg]
  let optionalInputs: [OptInputArg]
  let outputs: [OutputArg]

  /// Swift function name derived from camelCaseName (lowercased first letter).
  var swiftFuncName: String {
    guard !camelCaseName.isEmpty else { return "" }
    return camelCaseName.prefix(1).lowercased() + camelCaseName.dropFirst()
  }
}

/// A required input argument.
enum InputArgType {
  case doubleArray  // <Type>Double Array</Type>
  case priceOpen
  case priceHigh
  case priceLow
  case priceClose
  case priceVolume
  case priceOpenInterest
}

struct InputArg {
  let type: InputArgType
  let name: String  // e.g. "inReal", "High", "Volume"
}

/// An optional input argument.
enum OptInputArgType {
  case integer
  case double
  case maType
}

struct OptInputArg {
  let type: OptInputArgType
  let name: String  // e.g. "Time Period", "Fast Period", "MA Type"
  let shortDescription: String  // e.g. "Number of period"
  let range: (min: String, max: String)?  // e.g. (min: "2", max: "100000") for Integer/Double types
  let defaultValue: String  // raw string from XML, e.g. "30", "0"

  /// Swift parameter label derived from XML name (e.g. "Time Period" → "timePeriod").
  var swiftLabel: String { toSwiftLabel(name) }

  /// Swift type annotation for this optional input.
  var swiftType: String {
    switch type {
    case .integer: return "Int32"
    case .double: return "Double"
    case .maType: return "MAType"
    }
  }

  /// Swift default value expression.
  var swiftDefault: String {
    switch type {
    case .integer: return defaultValue
    case .double: return defaultValue
    case .maType: return ".\(maTypeCaseName(rawValue: defaultValue))"
    }
  }
}

/// An output argument.
enum OutputArgType {
  case doubleArray
  case integerArray
}

struct OutputArg {
  let type: OutputArgType
  let name: String  // e.g. "outReal", "outMACD", "outInteger"

  /// Swift variable name for the output buffer.
  var swiftName: String { name }
}

// MARK: - Helpers

private func toSwiftLabel(_ xmlName: String) -> String {
  // "Time Period" → "timePeriod", "Fast-K Period" → "fastKPeriod"
  let words =
    xmlName
    .replacingOccurrences(of: "-", with: " ")
    .components(separatedBy: " ")
    .filter { !$0.isEmpty }
  guard !words.isEmpty else { return xmlName }
  let first = words[0].lowercased()
  let rest = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
  return ([first] + rest).joined()
}

private func maTypeCaseName(rawValue: String) -> String {
  switch rawValue {
  case "0": return "sma"
  case "1": return "ema"
  case "2": return "wma"
  case "3": return "dema"
  case "4": return "tema"
  case "5": return "trima"
  case "6": return "kama"
  case "7": return "mama"
  case "8": return "t3"
  default: return "sma"
  }
}
