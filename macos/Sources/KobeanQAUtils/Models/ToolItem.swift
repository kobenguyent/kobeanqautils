import SwiftUI

enum ToolCategory: String, CaseIterable, Identifiable {
    case converters = "Converters & Formatters"
    case encoding = "Encoding & Security"
    case data = "Data & Generators"
    case network = "API & Network Testing"
    case testing = "Developer & QA Tools"
    case devops = "DevOps & Automation"
    case reference = "Reference & Learning"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .converters: return "arrow.triangle.2.circlepath"
        case .encoding: return "lock.shield"
        case .data: return "slider.horizontal.3"
        case .network: return "network"
        case .testing: return "hammer.fill"
        case .devops: return "terminal.fill"
        case .reference: return "book.fill"
        }
    }
}

enum QATool: String, CaseIterable, Identifiable {
    // Converters & Formatters
    case base64 = "base64"
    case jsonFormatter = "json-formatter"
    case jsonVisualizer = "json-visualizer"
    case timestamp = "timestamp"
    case colorConverter = "color-converter"
    case markdownConverter = "markdown-converter"
    case playwrightConverter = "playwright-converter"
    case htmlRenderer = "html-renderer"
    case mediaConverter = "media-converter"
    
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
    case graphqlClient = "graphql-client"
    case grpcClient = "grpc-client"
    case collectionManager = "collection-manager"
    case websiteScanner = "website-scanner"
    
    // Developer & QA Tools
    case diffComparator = "diff-comparator"
    case fileComparator = "file-comparator"
    case qrCode = "qr-code"
    case sqlHelper = "sql-helper"
    case testFileGen = "test-file-gen"
    case fileProcessor = "file-processor"
    case jiraComment = "jira-comment"
    case promptEnhancer = "prompt-enhancer"
    case jsonPromptBuilder = "json-prompt-builder"
    
    // DevOps & Automation
    case workflowGen = "workflow-gen"
    case sequenceDiagram = "sequence-diagram"
    case githubPrGen = "github-pr-gen"
    case logCollector = "log-collector"
    case kanbanBoard = "kanban-board"
    
    // Reference & Learning
    case commandBook = "command-book"
    case testingCheatsheet = "testing-cheatsheet"
    case localLlmGuide = "local-llm-guide"
    case qaChecklists = "qa-checklists"
    case telecomProtocols = "telecom-protocols"
    case istqbExam = "istqb-exam"
    case flashcards = "flashcards"
    case architectureGuides = "architecture-guides"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .base64: return "Base64 Encoder / Decoder"
        case .jsonFormatter: return "JSON Formatter & Validator"
        case .jsonVisualizer: return "JSON Tree Visualizer"
        case .timestamp: return "Unix Timestamp"
        case .colorConverter: return "Color Converter"
        case .markdownConverter: return "Markdown to Confluence Wiki"
        case .playwrightConverter: return "Playwright ↔ CodeceptJS"
        case .htmlRenderer: return "HTML & Web Previewer"
        case .mediaConverter: return "Media & Image Converter"
            
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
        case .graphqlClient: return "GraphQL Query Tester"
        case .grpcClient: return "gRPC Client Tester"
        case .collectionManager: return "API Collection Manager"
        case .websiteScanner: return "Website Health & Security Scanner"
            
        case .diffComparator: return "Text Diff Comparator"
        case .fileComparator: return "File Line-by-Line Comparator"
        case .qrCode: return "QR Code Generator"
        case .sqlHelper: return "SQL Helper & Formatter"
        case .testFileGen: return "Test File Generator"
        case .fileProcessor: return "File & Hex Inspector"
        case .jiraComment: return "Jira Comment & Panel Formatter"
        case .promptEnhancer: return "AI Prompt Enhancer"
        case .jsonPromptBuilder: return "JSON Multi-Turn Prompt Builder"
            
        case .workflowGen: return "CI/CD Pipeline Generator"
        case .sequenceDiagram: return "Sequence Diagram Generator"
        case .githubPrGen: return "GitHub PR Script Generator"
        case .logCollector: return "Log Collector & Bug Report"
        case .kanbanBoard: return "QA Kanban Task Board"
            
        case .commandBook: return "Developer Command Book"
        case .testingCheatsheet: return "Testing Frameworks Cheatsheet"
        case .localLlmGuide: return "Local LLM on Mac Guide"
        case .qaChecklists: return "QA Test Checklists Suite"
        case .telecomProtocols: return "Telecom Protocols (SIP, BLF, IVR)"
        case .istqbExam: return "ISTQB CTFL v4 Practice Exam"
        case .flashcards: return "ISTQB QA Flashcards (SM-2)"
        case .architectureGuides: return "Architecture & Infographics"
        }
    }
    
    var subtitle: String {
        switch self {
        case .base64: return "Encode and decode text or binary data to/from Base64"
        case .jsonFormatter: return "Prettify, minify, and validate JSON data structures"
        case .jsonVisualizer: return "Interactive hierarchical tree inspection of JSON nodes with keypaths"
        case .timestamp: return "Epoch timestamp converter with human date & relative time"
        case .colorConverter: return "Convert HEX, RGB, HSL, CMYK, SwiftUI Color and WCAG contrast"
        case .markdownConverter: return "Convert Markdown to Confluence Wiki / Jira markup & vice versa"
        case .playwrightConverter: return "Bidirectional test script converter between Playwright and CodeceptJS"
        case .htmlRenderer: return "Render HTML/CSS live with responsive viewport simulation"
        case .mediaConverter: return "Convert, resize, compress PNG/JPEG/TIFF/BMP and apply CoreImage filters"
            
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
        case .graphqlClient: return "Execute GraphQL queries and mutations with variables and headers"
        case .grpcClient: return "Test gRPC services and unary methods with protobuf JSON"
        case .collectionManager: return "Parse Postman v2.1 & Insomnia JSON collections, inspect requests and export cURL/Swift"
        case .websiteScanner: return "Audit SSL certificates, HTTP response latency, security headers (HSTS, CSP) and SEO metadata"
            
        case .diffComparator: return "Compare two text snippets side-by-side with line diffs"
        case .fileComparator: return "Side-by-side and unified line diff of two files with similarity %"
        case .qrCode: return "Create high-resolution QR codes from text and URLs"
        case .sqlHelper: return "Format SQL statements and generate mock INSERT queries"
        case .testFileGen: return "Generate dummy test files of exact byte/KB/MB sizes"
        case .fileProcessor: return "Analyze file metadata, checksums, hex dumps, and Base64 URIs"
        case .jiraComment: return "Format QA bug reports with Atlassian panels, tables, and notes"
        case .promptEnhancer: return "Transform raw instructions into structured system prompts"
        case .jsonPromptBuilder: return "Build multi-turn LLM prompts with OpenAI, Anthropic & Gemini export"
            
        case .workflowGen: return "Generate GitHub Actions, GitLab CI, and Jenkinsfile pipelines"
        case .sequenceDiagram: return "Generate Mermaid sequence diagrams from test flows and scripts"
        case .githubPrGen: return "Automate git branch creation, commits, and GitHub CLI PR creation"
        case .logCollector: return "Analyze log streams, filter error levels, and export bug issues"
        case .kanbanBoard: return "Track QA automation tasks with priority columns and persistence"
            
        case .commandBook: return "Quick-reference cheatsheet for Git, Docker, macOS, and Playwright"
        case .testingCheatsheet: return "Commands and comparison matrix for Playwright, CodeceptJS, Cypress, Pytest, and K6"
        case .localLlmGuide: return "Apple Silicon unified memory sizing, quantization table and Ollama/MLX setup"
        case .qaChecklists: return "Interactive Web, API, and Mobile test verification checklists with Markdown export"
        case .telecomProtocols: return "VoIP reference: SIP RFC 3261 methods/codes, BLF state simulator and IVR DTMF tree"
        case .istqbExam: return "Interactive CTFL v4 mock exam with timed quiz, instant rationales, and K-level syllabus tracking"
        case .flashcards: return "Study ISTQB CTFL principles with SM-2 spaced repetition"
        case .architectureGuides: return "Visual architectural deep-dives: AI Agents & MCP, CI/CD Pipeline, and API Styles"
        }
    }
    
    var icon: String {
        switch self {
        case .base64: return "doc.text.below.ecg"
        case .jsonFormatter: return "curlybraces"
        case .jsonVisualizer: return "list.bullet.indent"
        case .timestamp: return "clock"
        case .colorConverter: return "paintpalette"
        case .markdownConverter: return "doc.richtext"
        case .playwrightConverter: return "arrow.left.arrow.right"
        case .htmlRenderer: return "globe"
        case .mediaConverter: return "photo.stack"
            
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
        case .graphqlClient: return "hexagon.fill"
        case .grpcClient: return "cable.connector"
        case .collectionManager: return "tray.2.fill"
        case .websiteScanner: return "waveform.path.ecg"
            
        case .diffComparator: return "arrow.left.and.right"
        case .fileComparator: return "doc.on.doc.fill"
        case .qrCode: return "qrcode"
        case .sqlHelper: return "cylinder.split.1x2"
        case .testFileGen: return "arrow.down.doc"
        case .fileProcessor: return "doc.viewfinder"
        case .jiraComment: return "bubble.left.and.exclamationmark.bubble.right"
        case .promptEnhancer: return "sparkles"
        case .jsonPromptBuilder: return "puzzlepiece"
            
        case .workflowGen: return "gearshape.2.fill"
        case .sequenceDiagram: return "chart.bar.doc.horizontal"
        case .githubPrGen: return "arrow.triangle.branch"
        case .logCollector: return "list.bullet.rectangle"
        case .kanbanBoard: return "rectangle.split.3x1"
            
        case .commandBook: return "book.closed.fill"
        case .testingCheatsheet: return "text.badge.checkmark"
        case .localLlmGuide: return "apple.logo"
        case .qaChecklists: return "checklist"
        case .telecomProtocols: return "antenna.radiowaves.left.and.right"
        case .istqbExam: return "graduationcap.fill"
        case .flashcards: return "menucard"
        case .architectureGuides: return "cpu"
        }
    }
    
    var category: ToolCategory {
        switch self {
        case .base64, .jsonFormatter, .jsonVisualizer, .timestamp, .colorConverter, .markdownConverter, .playwrightConverter, .htmlRenderer, .mediaConverter:
            return .converters
        case .hashGen, .jwtDebugger, .passwordGen, .encryptionTool, .htpasswdGen:
            return .encoding
        case .uuidGen, .totp, .textAnalyzer, .loremIpsum, .dummyData:
            return .data
        case .restClient, .websocketClient, .graphqlClient, .grpcClient, .collectionManager, .websiteScanner:
            return .network
        case .diffComparator, .fileComparator, .qrCode, .sqlHelper, .testFileGen, .fileProcessor, .jiraComment, .promptEnhancer, .jsonPromptBuilder:
            return .testing
        case .workflowGen, .sequenceDiagram, .githubPrGen, .logCollector, .kanbanBoard:
            return .devops
        case .commandBook, .testingCheatsheet, .localLlmGuide, .qaChecklists, .telecomProtocols, .istqbExam, .flashcards, .architectureGuides:
            return .reference
        }
    }
    
    var searchKeywords: [String] {
        switch self {
        case .base64: return ["base64", "b64", "encode", "decode", "ascii", "binary"]
        case .jsonFormatter: return ["json", "format", "prettify", "minify", "validate", "parse", "beautify"]
        case .jsonVisualizer: return ["json", "visualizer", "tree", "nodes", "graph", "hierarchy", "keypath"]
        case .timestamp: return ["timestamp", "epoch", "unix", "date", "time", "clock", "seconds", "millis"]
        case .colorConverter: return ["color", "hex", "rgb", "hsl", "cmyk", "palette", "wcag", "contrast", "picker"]
        case .markdownConverter: return ["markdown", "confluence", "jira", "wiki", "markup", "convert", "table", "code"]
        case .playwrightConverter: return ["playwright", "codecept", "codeceptjs", "convert", "translate", "test", "automation"]
        case .htmlRenderer: return ["html", "css", "render", "preview", "webkit", "sandbox", "responsive", "iframe"]
        case .mediaConverter: return ["media", "image", "converter", "png", "jpeg", "jpg", "tiff", "bmp", "resize", "filter", "compress"]
            
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
        case .graphqlClient: return ["graphql", "gql", "query", "mutation", "variables", "schema", "api"]
        case .grpcClient: return ["grpc", "protobuf", "rpc", "unary", "streaming", "microservice", "proto"]
        case .collectionManager: return ["collection", "postman", "insomnia", "requests", "import", "curl", "export", "openapi"]
        case .websiteScanner: return ["website", "scanner", "health", "ssl", "cert", "security headers", "hsts", "csp", "seo", "audit"]
            
        case .diffComparator: return ["diff", "compare", "text", "difference", "changes"]
        case .fileComparator: return ["file", "comparator", "diff", "side by side", "unified diff", "patch", "similarity"]
        case .qrCode: return ["qr", "barcode", "code", "generator", "scan", "url"]
        case .sqlHelper: return ["sql", "database", "query", "format", "select", "insert", "db"]
        case .testFileGen: return ["file", "generator", "size", "bytes", "upload", "download", "boundary", "test"]
        case .fileProcessor: return ["file", "hex", "dump", "checksum", "mime", "binary", "inspector", "base64", "crlf"]
        case .jiraComment: return ["jira", "comment", "panel", "bug", "defect", "report", "atlassian", "ticket"]
        case .promptEnhancer: return ["prompt", "ai", "enhancer", "llm", "claude", "gpt", "system prompt", "instructions"]
        case .jsonPromptBuilder: return ["prompt", "json", "builder", "openai", "anthropic", "gemini", "messages", "multi-turn"]
            
        case .workflowGen: return ["github actions", "gitlab", "jenkins", "ci", "cd", "pipeline", "yaml", "workflow"]
        case .sequenceDiagram: return ["sequence", "diagram", "mermaid", "uml", "flow", "test flow", "actor"]
        case .githubPrGen: return ["github", "pr", "pull request", "branch", "git", "bash", "cli", "gh"]
        case .logCollector: return ["log", "collector", "error", "stack trace", "debug", "console", "github issue"]
        case .kanbanBoard: return ["kanban", "board", "task", "project", "todo", "agile", "cards", "columns"]
            
        case .commandBook: return ["command", "cheatsheet", "git", "docker", "bash", "playwright", "codeceptjs", "terminal"]
        case .testingCheatsheet: return ["testing", "cheatsheet", "playwright", "cypress", "pytest", "codeceptjs", "jest", "k6", "matrix"]
        case .localLlmGuide: return ["llm", "local", "mac", "apple silicon", "vram", "memory", "ollama", "mlx", "quantization", "16gb"]
        case .qaChecklists: return ["checklist", "web", "api", "mobile", "qa", "verification", "wcag", "security", "criteria"]
        case .telecomProtocols: return ["telecom", "sip", "blf", "ivr", "voip", "rfc3261", "dtmf", "phone", "asterisk", "pbx"]
        case .istqbExam: return ["istqb", "ctfl", "exam", "quiz", "test", "certification", "practice", "k-level", "syllabus"]
        case .flashcards: return ["flashcards", "istqb", "study", "learning", "spaced repetition", "sm2", "exam"]
        case .architectureGuides: return ["architecture", "mcp", "agents", "infographic", "cicd", "pyramid", "api types", "prompts"]
        }
    }
}
