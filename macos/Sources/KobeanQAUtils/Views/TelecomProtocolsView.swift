import SwiftUI
import AppKit

struct SipMethodItem: Identifiable {
    let id = UUID()
    let method: String
    let rfc: String
    let description: String
    let mnemonic: String
}

struct SipCodeItem: Identifiable {
    let id = UUID()
    let code: Int
    let phrase: String
    let category: String
    let explanation: String
}

struct TelecomProtocolsView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var activeTab: TelecomTab = .sip
    @State private var searchCodeText: String = ""
    @State private var selectedCodeCategory: String = "ALL"
    
    // BLF State Simulator
    @State private var blfState: BlfStatus = .terminated
    
    // IVR Simulator State
    @State private var ivrCurrentNode: String = "Main Menu"
    @State private var ivrHistory: [String] = ["Call connected. Welcome to Kobean Telecom QA!"]
    
    enum TelecomTab: String, CaseIterable, Identifiable {
        case sip = "SIP (RFC 3261)"
        case blf = "Busy Lamp Field (BLF)"
        case ivr = "IVR Tree Simulator"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .sip: return "antenna.radiowaves.left.and.right"
            case .blf: return "lightbulb.fill"
            case .ivr: return "phone.fill"
            }
        }
    }
    
    enum BlfStatus: String, CaseIterable {
        case terminated = "Terminated (Idle / Green)"
        case early = "Early (Ringing / Flashing Amber)"
        case confirmed = "Confirmed (In-Call / Solid Red)"
        
        var color: Color {
            switch self {
            case .terminated: return .green
            case .early: return .orange
            case .confirmed: return .red
            }
        }
        
        var ledSymbol: String {
            switch self {
            case .terminated: return "circle.fill"
            case .early: return "bell.badge.fill"
            case .confirmed: return "phone.down.circle.fill"
            }
        }
    }
    
    let sipMethods: [SipMethodItem] = [
        SipMethodItem(method: "INVITE", rfc: "RFC 3261", description: "Initiates a dialog and media session negotiation with SDP.", mnemonic: "💌 Wedding Invitation — invites party to start conversation; session begins only once accepted."),
        SipMethodItem(method: "ACK", rfc: "RFC 3261", description: "Confirms final response to an INVITE request (3-way handshake).", mnemonic: "🤝 Firm Handshake — seals the deal after receiver answers 200 OK."),
        SipMethodItem(method: "BYE", rfc: "RFC 3261", description: "Terminates an established dialog session.", mnemonic: "🚪 Saying Goodbye — cleanly hanging up the phone."),
        SipMethodItem(method: "CANCEL", rfc: "RFC 3261", description: "Cancels a pending request before final response (caller hung up while ringing).", mnemonic: "↩️ Changing Your Mind — hanging up before they pick up."),
        SipMethodItem(method: "REGISTER", rfc: "RFC 3261", description: "Binds user SIP URI to current IP contact address with registrar.", mnemonic: "📋 Hotel Guestbook — announcing 'I am in Room 402' so calls can locate you."),
        SipMethodItem(method: "OPTIONS", rfc: "RFC 3261", description: "Queries supported SIP methods, codecs, and server capabilities.", mnemonic: "🩺 Health Check — checking if server or peer is alive and capable.")
    ]
    
    let sipCodes: [SipCodeItem] = [
        SipCodeItem(code: 100, phrase: "Trying", category: "1xx Provisional", explanation: "Next-hop server has received request and is processing."),
        SipCodeItem(code: 180, phrase: "Ringing", category: "1xx Provisional", explanation: "Destination User Agent is alerting/ringing the callee."),
        SipCodeItem(code: 183, phrase: "Session Progress", category: "1xx Provisional", explanation: "Early media in progress (e.g. carrier ringback tone or announcement)."),
        SipCodeItem(code: 200, phrase: "OK", category: "2xx Success", explanation: "Request has succeeded; call answered, registration accepted."),
        SipCodeItem(code: 301, phrase: "Moved Permanently", category: "3xx Redirection", explanation: "User no longer at this URI; permanent new contact specified."),
        SipCodeItem(code: 302, phrase: "Moved Temporarily", category: "3xx Redirection", explanation: "Call forwarding / temporary alternate address."),
        SipCodeItem(code: 401, phrase: "Unauthorized", category: "4xx Client Error", explanation: "Requires digest authentication credentials."),
        SipCodeItem(code: 403, phrase: "Forbidden", category: "4xx Client Error", explanation: "Server understands request but refuses to fulfill it."),
        SipCodeItem(code: 404, phrase: "Not Found", category: "4xx Client Error", explanation: "User does not exist in domain or dialplan."),
        SipCodeItem(code: 486, phrase: "Busy Here", category: "4xx Client Error", explanation: "Callee device is currently occupied on another call."),
        SipCodeItem(code: 487, phrase: "Request Terminated", category: "4xx Client Error", explanation: "Request terminated by CANCEL or BYE."),
        SipCodeItem(code: 500, phrase: "Server Internal Error", category: "5xx Server Error", explanation: "PBX / SIP Proxy encountered unexpected error."),
        SipCodeItem(code: 503, phrase: "Service Unavailable", category: "5xx Server Error", explanation: "SIP gateway overload or maintenance downtime."),
        SipCodeItem(code: 603, phrase: "Decline", category: "6xx Global Failure", explanation: "Callee explicitly declined call and does not wish to accept anywhere.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .telecomProtocols, onReset: resetAll)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            Picker("Domain", selection: $activeTab) {
                ForEach(TelecomTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            switch activeTab {
            case .sip:
                sipProtocolsView
            case .blf:
                blfSimulatorView
            case .ivr:
                ivrSimulatorView
            }
        }
    }
    
    // MARK: - SIP Protocols Tab
    private var sipProtocolsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Overview & Mnemonic Banner
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session Initiation Protocol (SIP)")
                        .font(.headline)
                    Text("Text-based signaling protocol modeled on HTTP/SMTP (RFC 3261) used to establish, modify, and terminate multimedia sessions (VoIP, WebRTC, LTE VoLTE).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Methods
                VStack(alignment: .leading, spacing: 10) {
                    Text("Core SIP Methods & Mnemonics")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(sipMethods) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Text(item.method)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .frame(width: 90, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.description)
                                        .font(.subheadline)
                                    
                                    Text("💡 " + item.mnemonic)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // Response Codes
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SIP Response Codes (1xx–6xx)")
                            .font(.headline)
                        Spacer()
                        
                        TextField("Filter codes (e.g. 486)...", text: $searchCodeText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    VStack(spacing: 6) {
                        ForEach(filteredCodes) { code in
                            HStack(spacing: 12) {
                                Text("\(code.code)")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(codeColor(code.code))
                                    .frame(width: 45, alignment: .leading)
                                
                                Text(code.phrase)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 170, alignment: .leading)
                                
                                Text(code.explanation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(code.category)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - BLF Simulator Tab
    private var blfSimulatorView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Explanation
                VStack(alignment: .leading, spacing: 6) {
                    Text("Busy Lamp Field (BLF) / RFC 4235")
                        .font(.headline)
                    Text("Hardware LED indicator and software subscription protocol allowing an IP phone / receptionist console to monitor line statuses across PBX extensions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Interactive Phone Lamp Simulator
                VStack(spacing: 16) {
                    Text("VOIP DESK PHONE BLF DISPLAY SIMULATION")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 24) {
                        // Phone Extension Card
                        VStack(spacing: 10) {
                            Circle()
                                .fill(blfState.color)
                                .frame(width: 44, height: 44)
                                .shadow(color: blfState.color.opacity(0.6), radius: 10)
                            
                            Text("Ext 104 (Alice)")
                                .font(.headline)
                            
                            Text(blfState.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .frame(width: 260)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(blfState.color.opacity(0.4), lineWidth: 2)
                        )
                        
                        // State Triggers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Simulate PBX Event:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(BlfStatus.allCases, id: \.self) { status in
                                Button(action: { blfState = status }) {
                                    HStack {
                                        Image(systemName: status.ledSymbol)
                                            .foregroundColor(status.color)
                                        Text(status.rawValue)
                                        Spacer()
                                        if blfState == status {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(8)
                                    .frame(width: 280)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
                
                // Generated RFC 4235 SIP NOTIFY XML
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("RFC 4235 Dialog-Info NOTIFY Payload", systemImage: "doc.text")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            ClipboardHelper.copy(generateBlfXml())
                            appState.showToast("XML copied")
                        }) {
                            Label("Copy XML", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Text(generateBlfXml())
                        .font(.system(.caption, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - IVR Simulator Tab
    private var ivrSimulatorView: some View {
        VStack(spacing: 12) {
            HSplitView {
                // Keypad
                VStack(spacing: 12) {
                    Text("DTMF KEYPAD")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    let rows = [
                        [("1", ""), ("2", "ABC"), ("3", "DEF")],
                        [("4", "GHI"), ("5", "JKL"), ("6", "MNO")],
                        [("7", "PQRS"), ("8", "TUV"), ("9", "WXYZ")],
                        [("*", ""), ("0", "+"), ("#", "")]
                    ]
                    
                    VStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { r in
                            HStack(spacing: 8) {
                                ForEach(rows[r], id: \.0) { key, sub in
                                    Button(action: { pressIvrKey(key) }) {
                                        VStack(spacing: 1) {
                                            Text(key)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                            if !sub.isEmpty {
                                                Text(sub)
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(width: 50, height: 46)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Button("Hang Up / Reset") {
                        ivrCurrentNode = "Main Menu"
                        ivrHistory = ["Call reset to Main Menu."]
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.bottom, 8)
                }
                .frame(width: 200)
                
                // Call Flow Log & Tree
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Current Menu: \(ivrCurrentNode)", systemImage: "waveform")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // IVR Script Options
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompts for current node:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currentIvrPrompt)
                            .font(.subheadline)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal)
                    
                    // Call Log
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interaction History:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(ivrHistory.enumerated()), id: \.offset) { _, entry in
                                    Text("• \(entry)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .frame(minWidth: 350)
            }
        }
    }
    
    // MARK: - Logic & Helpers
    private var filteredCodes: [SipCodeItem] {
        guard !searchCodeText.isEmpty else { return sipCodes }
        return sipCodes.filter {
            String($0.code).contains(searchCodeText) ||
            $0.phrase.localizedCaseInsensitiveContains(searchCodeText) ||
            $0.explanation.localizedCaseInsensitiveContains(searchCodeText)
        }
    }
    
    private func codeColor(_ code: Int) -> Color {
        switch code / 100 {
        case 1: return .blue
        case 2: return .green
        case 3: return .cyan
        case 4: return .orange
        case 5: return .red
        case 6: return .purple
        default: return .secondary
        }
    }
    
    private func generateBlfXml() -> String {
        let stateStr = blfState == .terminated ? "terminated" : (blfState == .early ? "early" : "confirmed")
        return """
        <?xml version="1.0"?>
        <dialog-info xmlns="urn:ietf:params:xml:ns:dialog-info"
                     version="1"
                     state="full"
                     entity="sip:alice@pbx.example.com">
          <dialog id="as8921" call-id="d89a2-991" direction="recipient">
            <state>\(stateStr)</state>
            <local>
              <identity display="Alice">sip:alice@pbx.example.com</identity>
              <target uri="sip:alice@192.168.1.104"/>
            </local>
          </dialog>
        </dialog-info>
        """
    }
    
    private var currentIvrPrompt: String {
        switch ivrCurrentNode {
        case "Main Menu":
            return "Press 1 for Sales Inquiry.\nPress 2 for Technical Support.\nPress 0 for Receptionist."
        case "Sales":
            return "Sales Department: Press 1 for Enterprise Licensing, 2 for Billing, * to return to Main Menu."
        case "Support":
            return "Technical Support: Press 1 for KobeanQA Cloud, 2 for Native Mac App, * to return to Main Menu."
        default:
            return "Connected to agent queue. Please hold..."
        }
    }
    
    private func pressIvrKey(_ key: String) {
        if key == "*" {
            ivrCurrentNode = "Main Menu"
            ivrHistory.append("DTMF '*': Returned to Main Menu")
            return
        }
        
        switch ivrCurrentNode {
        case "Main Menu":
            if key == "1" {
                ivrCurrentNode = "Sales"
                ivrHistory.append("DTMF '1': Routed to Sales Department")
            } else if key == "2" {
                ivrCurrentNode = "Support"
                ivrHistory.append("DTMF '2': Routed to Technical Support")
            } else if key == "0" {
                ivrCurrentNode = "Operator Queue"
                ivrHistory.append("DTMF '0': Connecting to Operator...")
            }
        case "Sales":
            ivrHistory.append("DTMF '\(key)': Transferring to Sales representative...")
        case "Support":
            ivrHistory.append("DTMF '\(key)': Transferring to QA Specialist queue...")
        default:
            ivrHistory.append("DTMF '\(key)': Key acknowledged.")
        }
    }
    
    private func resetAll() {
        searchCodeText = ""
        blfState = .terminated
        ivrCurrentNode = "Main Menu"
        ivrHistory = ["Call reset."]
    }
}
