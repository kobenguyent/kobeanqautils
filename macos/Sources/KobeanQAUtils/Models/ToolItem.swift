import SwiftUI

enum ToolCategory: String, CaseIterable, Identifiable {
    case converters = "Converters & Formatters"
    case encoding = "Encoding & Security"
    case data = "Data & Generators"
    case network = "API & Network Testing"
    case testing = "Developer & QA Tools"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .converters: return "arrow.triangle.2.circlepath"
        case .encoding: return "lock.shield"
        case .data: return "slider.horizontal.3"
        case .network: return "network"
        case .testing: return "hammer.fill"
        }
    }
}

enum QATool: String, CaseIterable, Identifiable {
    // Converters & Formatters
    case base64 = "base64"
    case jsonFormatter = "json-formatter"
    case timestamp = "timestamp"
    case colorConverter = "color-converter"
    case markdownConverter = "markdown-converter"
    
    // Encoding & Security
    case hashGen = "hash-gen"
    case jwtDebugger = "jwt-debugger"
    case passwordGen = "password-gen"
    case encryptionTool = "encryption-tool"
    case htpasswdGen = "htpasswd-gen"
    
    // Data & Generators
    case uuidGen = "uuid-gen"
    case totp = "totp"
    case textAnalyzer = "text-analyzer"
    case loremIpsum = "lorem-ipsum"
    case dummyData = "dummy-data"
    
    // API & Network Testing
    case restClient = "rest-client"
    case websocketClient = "websocket-client"
    
    // Developer & QA Tools
    case diffComparator = "diff-comparator"
    case qrCode = "qr-code"
    case sqlHelper = "sql-helper"
    case testFileGen = "test-file-gen"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .base64: return "Base64 Encoder / Decoder"
        case .jsonFormatter: return "JSON Formatter & Validator"
        case .timestamp: return "Unix Timestamp"
        case .colorConverter: return "Color Converter"
        case .markdownConverter: return "Markdown to Confluence Wiki"
            
        case .hashGen: return "Hash & Checksum"
        case .jwtDebugger: return "JWT Debugger"
        case .passwordGen: return "Password Generator"
        case .encryptionTool: return "AES-256-GCM Encryption"
        case .htpasswdGen: return "HTPasswd Generator"
            
        case .uuidGen: return "UUID / GUID Generator"
        case .totp: return "TOTP 2FA Authenticator"
        case .textAnalyzer: return "Text & Character Analyzer"
        case .loremIpsum: return "Lorem Ipsum Generator"
        case .dummyData: return "Dummy Data Generator"
            
        case .restClient: return "REST API Tester"
        case .websocketClient: return "WebSocket Client Tester"
            
        case .diffComparator: return "Text Diff Comparator"
        case .qrCode: return "QR Code Generator"
        case .sqlHelper: return "SQL Helper & Formatter"
        case .testFileGen: return "Test File Generator"
        }
    }
    
    var subtitle: String {
        switch self {
        case .base64: return "Encode and decode text or binary data to/from Base64"
        case .jsonFormatter: return "Prettify, minify, and validate JSON data structures"
        case .timestamp: return "Epoch timestamp converter with human date & relative time"
        case .colorConverter: return "Convert HEX, RGB, HSL, CMYK, SwiftUI Color and WCAG contrast"
        case .markdownConverter: return "Convert Markdown to Confluence Wiki / Jira markup & vice versa"
            
        case .hashGen: return "Generate MD5, SHA-1, SHA-256, SHA-512 & HMAC"
        case .jwtDebugger: return "Decode, inspect claims and verify expiration of JWT tokens"
        case .passwordGen: return "Generate secure customizable passwords with entropy analysis"
        case .encryptionTool: return "Authenticated AES-256-GCM encryption & decryption"
        case .htpasswdGen: return "Generate Apache / Nginx .htpasswd basic auth records"
            
        case .uuidGen: return "Generate random UUID v4 with bulk and case options"
        case .totp: return "Generate 2FA authentication tokens with live countdown"
        case .textAnalyzer: return "Count characters, words, sentences, lines and byte length"
        case .loremIpsum: return "Generate placeholder dummy text by paragraphs, sentences or words"
        case .dummyData: return "Generate realistic mock profiles in JSON, CSV or SQL"
            
        case .restClient: return "Send HTTP requests, test headers and inspect responses"
        case .websocketClient: return "Live WebSocket traffic tester with ping/pong and logs"
            
        case .diffComparator: return "Compare two text snippets side-by-side with line diffs"
        case .qrCode: return "Create high-resolution QR codes from text and URLs"
        case .sqlHelper: return "Format SQL statements and generate mock INSERT queries"
        case .testFileGen: return "Generate dummy test files of exact byte/KB/MB sizes"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "doc.text.below.ecg"
        case .jsonFormatter: return "curlybraces"
        case .timestamp: return "clock"
        case .colorConverter: return "paintpalette"
        case .markdownConverter: return "doc.richtext"
            
        case .hashGen: return "number"
        case .jwtDebugger: return "key.horizontal"
        case .passwordGen: return "key.fill"
        case .encryptionTool: return "lock.shield.fill"
        case .htpasswdGen: return "person.badge.key"
            
        case .uuidGen: return "tag"
        case .totp: return "shield.checkered"
        case .textAnalyzer: return "character.cursor.ibeam"
        case .loremIpsum: return "paragraphsign"
        case .dummyData: return "person.3.fill"
            
        case .restClient: return "network"
        case .websocketClient: return "bolt.horizontal"
            
        case .diffComparator: return "arrow.left.and.right"
        case .qrCode: return "qrcode"
        case .sqlHelper: return "cylinder.split.1x2"
        case .testFileGen: return "arrow.down.doc"
        }
    }
    
    var category: ToolCategory {
        switch self {
        case .base64, .jsonFormatter, .timestamp, .colorConverter, .markdownConverter:
            return .converters
        case .hashGen, .jwtDebugger, .passwordGen, .encryptionTool, .htpasswdGen:
            return .encoding
        case .uuidGen, .totp, .textAnalyzer, .loremIpsum, .dummyData:
            return .data
        case .restClient, .websocketClient:
            return .network
        case .diffComparator, .qrCode, .sqlHelper, .testFileGen:
            return .testing
        }
    }
    
    var searchKeywords: [String] {
        switch self {
        case .base64: return ["base64", "b64", "encode", "decode", "ascii", "binary"]
        case .jsonFormatter: return ["json", "format", "prettify", "minify", "validate", "parse", "beautify"]
        case .timestamp: return ["timestamp", "epoch", "unix", "date", "time", "clock", "seconds", "millis"]
        case .colorConverter: return ["color", "hex", "rgb", "hsl", "cmyk", "palette", "wcag", "contrast", "picker"]
        case .markdownConverter: return ["markdown", "confluence", "jira", "wiki", "markup", "convert", "table", "code"]
            
        case .hashGen: return ["hash", "md5", "sha", "sha256", "sha512", "hmac", "crypto", "checksum"]
        case .jwtDebugger: return ["jwt", "token", "auth", "bearer", "claims", "json web token", "expire"]
        case .passwordGen: return ["password", "passcode", "generate", "random", "security", "entropy"]
        case .encryptionTool: return ["encrypt", "decrypt", "aes", "gcm", "cipher", "security", "secret", "crypto"]
        case .htpasswdGen: return ["htpasswd", "apache", "nginx", "auth", "basic", "sha1", "apr1", "credentials"]
            
        case .uuidGen: return ["uuid", "guid", "v4", "unique", "identifier"]
        case .totp: return ["totp", "otp", "2fa", "mfa", "authenticator", "google authenticator"]
        case .textAnalyzer: return ["text", "count", "words", "characters", "length", "lines", "bytes"]
        case .loremIpsum: return ["lorem", "ipsum", "dummy", "placeholder", "filler", "paragraphs", "latin"]
        case .dummyData: return ["dummy", "fake", "mock", "faker", "users", "csv", "json", "generator", "sql"]
            
        case .restClient: return ["rest", "api", "http", "curl", "postman", "get", "post", "fetch", "network"]
        case .websocketClient: return ["websocket", "ws", "wss", "socket", "realtime", "ping", "pong", "traffic"]
            
        case .diffComparator: return ["diff", "compare", "text", "difference", "changes"]
        case .qrCode: return ["qr", "barcode", "code", "generator", "scan", "url"]
        case .sqlHelper: return ["sql", "database", "query", "format", "select", "insert", "db"]
        case .testFileGen: return ["file", "generator", "size", "bytes", "upload", "download", "boundary", "test"]
        }
    }
}
