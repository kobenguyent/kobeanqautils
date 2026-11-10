import SwiftUI

enum ToolCategory: String, CaseIterable, Identifiable {
    case encoding = "Encoding & Security"
    case data = "Data & Generators"
    case testing = "Developer & QA Tools"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .encoding: return "lock.shield"
        case .data: return "slider.horizontal.3"
        case .testing: return "hammer.fill"
        }
    }
}

enum QATool: String, CaseIterable, Identifiable {
    // Encoding & Security
    case base64 = "base64"
    case hashGen = "hash-gen"
    case jwtDebugger = "jwt-debugger"
    case passwordGen = "password-gen"
    
    // Data & Generators
    case uuidGen = "uuid-gen"
    case timestamp = "timestamp"
    case totp = "totp"
    case textAnalyzer = "text-analyzer"
    
    // Developer & QA Tools
    case jsonFormatter = "json-formatter"
    case restClient = "rest-client"
    case diffComparator = "diff-comparator"
    case qrCode = "qr-code"
    case sqlHelper = "sql-helper"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .base64: return "Base64 Encoder / Decoder"
        case .hashGen: return "Hash & Checksum"
        case .jwtDebugger: return "JWT Debugger"
        case .passwordGen: return "Password Generator"
        case .uuidGen: return "UUID / GUID Generator"
        case .timestamp: return "Unix Timestamp"
        case .totp: return "TOTP 2FA Authenticator"
        case .textAnalyzer: return "Text & Character Analyzer"
        case .jsonFormatter: return "JSON Formatter & Validator"
        case .restClient: return "REST API Tester"
        case .diffComparator: return "Text Diff Comparator"
        case .qrCode: return "QR Code Generator"
        case .sqlHelper: return "SQL Helper & Formatter"
        }
    }
    
    var subtitle: String {
        switch self {
        case .base64: return "Encode and decode text or binary data to/from Base64"
        case .hashGen: return "Generate MD5, SHA-1, SHA-256, SHA-512 & HMAC"
        case .jwtDebugger: return "Decode, inspect claims and verify expiration of JWT tokens"
        case .passwordGen: return "Generate secure customizable passwords with entropy analysis"
        case .uuidGen: return "Generate random UUID v4 with bulk and case options"
        case .timestamp: return "Epoch timestamp converter with human date & relative time"
        case .totp: return "Generate 2FA authentication tokens with live countdown"
        case .textAnalyzer: return "Count characters, words, sentences, lines and byte length"
        case .jsonFormatter: return "Prettify, minify, and validate JSON data structures"
        case .restClient: return "Send HTTP requests, test headers and inspect responses"
        case .diffComparator: return "Compare two text snippets side-by-side with line diffs"
        case .qrCode: return "Create high-resolution QR codes from text and URLs"
        case .sqlHelper: return "Format SQL statements and generate mock INSERT queries"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "doc.text.below.ecg"
        case .hashGen: return "number"
        case .jwtDebugger: return "key.horizontal"
        case .passwordGen: return "key.fill"
        case .uuidGen: return "tag"
        case .timestamp: return "clock"
        case .totp: return "shield.checkered"
        case .textAnalyzer: return "character.cursor.ibeam"
        case .jsonFormatter: return "curlybraces"
        case .restClient: return "network"
        case .diffComparator: return "arrow.left.and.right"
        case .qrCode: return "qrcode"
        case .sqlHelper: return "cylinder.split.1x2"
        }
    }
    
    var category: ToolCategory {
        switch self {
        case .base64, .hashGen, .jwtDebugger, .passwordGen:
            return .encoding
        case .uuidGen, .timestamp, .totp, .textAnalyzer:
            return .data
        case .jsonFormatter, .restClient, .diffComparator, .qrCode, .sqlHelper:
            return .testing
        }
    }
    
    var searchKeywords: [String] {
        switch self {
        case .base64: return ["base64", "b64", "encode", "decode", "ascii", "binary"]
        case .hashGen: return ["hash", "md5", "sha", "sha256", "sha512", "hmac", "crypto", "checksum"]
        case .jwtDebugger: return ["jwt", "token", "auth", "bearer", "claims", "json web token", "expire"]
        case .passwordGen: return ["password", "passcode", "generate", "random", "security", "entropy"]
        case .uuidGen: return ["uuid", "guid", "v4", "unique", "identifier"]
        case .timestamp: return ["timestamp", "epoch", "unix", "date", "time", "clock", "seconds", "millis"]
        case .totp: return ["totp", "otp", "2fa", "mfa", "authenticator", "google authenticator"]
        case .textAnalyzer: return ["text", "count", "words", "characters", "length", "lines", "bytes"]
        case .jsonFormatter: return ["json", "format", "prettify", "minify", "validate", "parse", "beautify"]
        case .restClient: return ["rest", "api", "http", "curl", "postman", "get", "post", "fetch", "network"]
        case .diffComparator: return ["diff", "compare", "text", "difference", "changes"]
        case .qrCode: return ["qr", "barcode", "code", "generator", "scan", "url"]
        case .sqlHelper: return ["sql", "database", "query", "format", "select", "insert", "db"]
        }
    }
}
