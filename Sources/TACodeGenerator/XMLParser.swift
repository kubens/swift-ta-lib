// Minimal XML tokenizer + state-machine parser.
// No Foundation — uses only Swift stdlib and C stdlib for file I/O.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// MARK: - File I/O (no Foundation)

func readFileContents(atPath path: String) throws -> String {
  guard let file = fopen(path, "r") else {
    throw ParseError.cannotOpenFile(path)
  }
  defer { fclose(file) }
  var result = ""
  result.reserveCapacity(256 * 1024)
  var buf = [CChar](repeating: 0, count: 8192)
  while fgets(&buf, Int32(buf.count), file) != nil {
    buf.withUnsafeBytes { raw in
      let len = raw.firstIndex(of: 0) ?? raw.count
      result += String(decoding: raw.prefix(len), as: UTF8.self)
    }
  }
  return result
}

// MARK: - Tokenizer

private enum XMLToken {
  case startTag(String)
  case endTag(String)
  case text(String)
}

private func tokenize(_ xml: String) -> [XMLToken] {
  var tokens: [XMLToken] = []
  tokens.reserveCapacity(8192)
  var idx = xml.startIndex

  while idx < xml.endIndex {
    if xml[idx] == "<" {
      let afterLt = xml.index(after: idx)
      guard let gtIdx = xml[afterLt...].firstIndex(of: ">") else { break }
      let raw = xml[afterLt..<gtIdx]
      let firstChar = raw.first

      if firstChar == "/" {
        // End tag </Foo>
        tokens.append(.endTag(String(raw.dropFirst()).trimmedXML()))
      } else if firstChar != "!" && firstChar != "?" {
        // Start tag <Foo> — we have no attributes in this XML
        let name = raw.split(separator: " ", maxSplits: 1).first.map(String.init) ?? String(raw)
        tokens.append(.startTag(name.trimmedXML()))
      }
      idx = xml.index(after: gtIdx)
    } else {
      // Text content
      let textStart = idx
      while idx < xml.endIndex && xml[idx] != "<" {
        idx = xml.index(after: idx)
      }
      let text = String(xml[textStart..<idx]).trimmedXML()
      if !text.isEmpty {
        tokens.append(.text(text))
      }
    }
  }
  return tokens
}

extension String {
  /// Trims ASCII whitespace (no Foundation CharacterSet needed).
  fileprivate func trimmedXML() -> String {
    let trimmed = self.drop(while: { $0.isWhitespace }).reversed().drop(while: { $0.isWhitespace }).reversed()
    return String(trimmed)
  }
}

// MARK: - State-machine parser

struct TAFuncAPIParser {
  static func parse(path: String) throws -> [TAFunction] {
    let xml = try readFileContents(atPath: path)
    let tokens = tokenize(xml)
    return try buildFunctions(from: tokens)
  }

  private static func buildFunctions(from tokens: [XMLToken]) throws -> [TAFunction] {
    var functions: [TAFunction] = []
    var i = 0

    while i < tokens.count {
      if case .startTag("FinancialFunction") = tokens[i] {
        let (fn, next) = parseFunction(tokens: tokens, from: i + 1)
        functions.append(fn)
        i = next
      } else {
        i += 1
      }
    }
    return functions
  }

  // MARK: Parse one <FinancialFunction> block

  private static func parseFunction(tokens: [XMLToken], from start: Int) -> (TAFunction, Int) {
    var i = start
    var abbreviation = ""
    var camelCaseName = ""
    var shortDescription = ""
    var groupId = ""
    var requiredInputs: [InputArg] = []
    var optionalInputs: [OptInputArg] = []
    var outputs: [OutputArg] = []

    while i < tokens.count {
      switch tokens[i] {
      case .endTag("FinancialFunction"):
        let fn = TAFunction(
          abbreviation: abbreviation,
          camelCaseName: camelCaseName,
          shortDescription: shortDescription,
          groupId: groupId,
          requiredInputs: requiredInputs,
          optionalInputs: optionalInputs,
          outputs: outputs
        )
        return (fn, i + 1)

      case .startTag("Abbreviation"):
        abbreviation = nextText(tokens: tokens, idx: &i)
      case .startTag("CamelCaseName"):
        camelCaseName = nextText(tokens: tokens, idx: &i)
      case .startTag("ShortDescription"):
        if shortDescription.isEmpty { shortDescription = nextText(tokens: tokens, idx: &i) } else { i += 1 }
      case .startTag("GroupId"):
        groupId = nextText(tokens: tokens, idx: &i)

      case .startTag("RequiredInputArgument"):
        let (arg, next) = parseRequiredInput(tokens: tokens, from: i + 1)
        if let arg { requiredInputs.append(arg) }
        i = next

      case .startTag("OptionalInputArgument"):
        let (arg, next) = parseOptionalInput(tokens: tokens, from: i + 1)
        if let arg { optionalInputs.append(arg) }
        i = next

      case .startTag("OutputArgument"):
        let (arg, next) = parseOutputArg(tokens: tokens, from: i + 1)
        outputs.append(arg)
        i = next

      default:
        i += 1
      }
    }
    // Fallback (malformed XML)
    return (
      TAFunction(
        abbreviation: abbreviation, camelCaseName: camelCaseName,
        shortDescription: shortDescription, groupId: groupId,
        requiredInputs: requiredInputs, optionalInputs: optionalInputs,
        outputs: outputs), i
    )
  }

  // MARK: <RequiredInputArgument>

  private static func parseRequiredInput(tokens: [XMLToken], from start: Int) -> (InputArg?, Int) {
    var i = start
    var name = ""
    var type = ""
    while i < tokens.count {
      switch tokens[i] {
      case .endTag("RequiredInputArgument"):
        guard let t = parseInputArgType(type) else { return (nil, i + 1) }
        return (InputArg(type: t, name: name), i + 1)
      case .startTag("Name"): name = nextText(tokens: tokens, idx: &i)
      case .startTag("Type"): type = nextText(tokens: tokens, idx: &i)
      default: i += 1
      }
    }
    return (nil, i)
  }

  // MARK: <OptionalInputArgument>

  private static func parseOptionalInput(tokens: [XMLToken], from start: Int) -> (OptInputArg?, Int) {
    var i = start
    var name = ""
    var type = ""
    var shortDescription = ""
    var minimum = ""
    var maximum = ""
    var defaultValue = "0"
    var inRange = false
    while i < tokens.count {
      switch tokens[i] {
      case .endTag("OptionalInputArgument"):
        guard let t = parseOptInputArgType(type) else { return (nil, i + 1) }
        let range: (min: String, max: String)? =
          (!minimum.isEmpty && !maximum.isEmpty) ? (min: minimum, max: maximum) : nil
        return (
          OptInputArg(
            type: t, name: name, shortDescription: shortDescription, range: range,
            defaultValue: defaultValue), i + 1
        )
      case .startTag("Name"): name = nextText(tokens: tokens, idx: &i)
      case .startTag("ShortDescription"): shortDescription = nextText(tokens: tokens, idx: &i)
      case .startTag("Type"): type = nextText(tokens: tokens, idx: &i)
      case .startTag("Range"): inRange = true; i += 1
      case .endTag("Range"): inRange = false; i += 1
      case .startTag("Minimum") where inRange: minimum = nextText(tokens: tokens, idx: &i)
      case .startTag("Maximum") where inRange: maximum = nextText(tokens: tokens, idx: &i)
      case .startTag("DefaultValue"): defaultValue = nextText(tokens: tokens, idx: &i)
      default: i += 1
      }
    }
    return (nil, i)
  }

  // MARK: <OutputArgument>

  private static func parseOutputArg(tokens: [XMLToken], from start: Int) -> (OutputArg, Int) {
    var i = start
    var name = ""
    var type = ""
    while i < tokens.count {
      switch tokens[i] {
      case .endTag("OutputArgument"):
        let outType: OutputArgType = type == "Integer Array" ? .integerArray : .doubleArray
        return (OutputArg(type: outType, name: name), i + 1)
      case .startTag("Name"): name = nextText(tokens: tokens, idx: &i)
      case .startTag("Type"): type = nextText(tokens: tokens, idx: &i)
      default: i += 1
      }
    }
    return (OutputArg(type: .doubleArray, name: name), i)
  }

  // MARK: - Helpers

  /// Advances past the text node and closing tag, returns the text.
  private static func nextText(tokens: [XMLToken], idx: inout Int) -> String {
    idx += 1
    var text = ""
    if idx < tokens.count, case .text(let t) = tokens[idx] {
      text = t
      idx += 1
    }
    // Skip the matching end tag
    if idx < tokens.count, case .endTag = tokens[idx] { idx += 1 }
    return text
  }

  private static func parseInputArgType(_ type: String) -> InputArgType? {
    switch type {
    case "Double Array": return .doubleArray
    case "Open": return .priceOpen
    case "High": return .priceHigh
    case "Low": return .priceLow
    case "Close": return .priceClose
    case "Volume": return .priceVolume
    case "Open Interest": return .priceOpenInterest
    default: return nil
    }
  }

  private static func parseOptInputArgType(_ type: String) -> OptInputArgType? {
    switch type {
    case "Integer": return .integer
    case "Double": return .double
    case "MA Type": return .maType
    default: return nil
    }
  }
}

enum ParseError: Error {
  case cannotOpenFile(String)
}
