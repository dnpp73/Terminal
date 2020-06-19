import Foundation

func debugLog(fileName: String = #file, line: Int = #line, functionName: String = #function, _ msg: String = "") {
    #if DEBUG
    print("\(Date().description) [\(fileName.split(separator: "/").last ?? "") @L\(line) \(functionName)] " + msg)
    #endif
}
