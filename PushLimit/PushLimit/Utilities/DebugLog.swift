import Foundation

/// Debug-only logging. Stripped from Release builds so PII never reaches device logs in production.
enum DebugLog {
    static func log(
        _ items: Any...,
        separator: String = " ",
        terminator: String = "\n",
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: separator)
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(message)", terminator: terminator)
        #endif
    }
}
