import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

struct QRCodeToolView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var text: String = "https://github.com/kobenguyent/kobeanqautils"
    @State private var correctionLevel: String = "M"
    
    private let context = CIContext()
    
    private var qrImage: NSImage? {
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return nil }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let outputCI = filter.outputImage else { return nil }
        
        // Scale up sharp without anti-aliasing
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCI = outputCI.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledCI, from: scaledCI.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolHeaderView(tool: .qrCode) {
                    text = "https://github.com/kobenguyent/kobeanqautils"
                }
                
                // Input Text
                VStack(alignment: .leading, spacing: 6) {
                    Text("Text or URL to Encode")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter URL or plain text...", text: $text)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body))
                }
                
                HStack(spacing: 20) {
                    Picker("Error Correction:", selection: $correctionLevel) {
                        Text("Low (7%)").tag("L")
                        Text("Medium (15%)").tag("M")
                        Text("Quartile (25%)").tag("Q")
                        Text("High (30%)").tag("H")
                    }
                    .frame(width: 220)
                    
                    Spacer()
                }
                
                // QR Display
                VStack(spacing: 16) {
                    if let img = qrImage {
                        Image(nsImage: img)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                if let img = qrImage {
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.writeObjects([img])
                                    appState.showToast("QR Code image copied!")
                                }
                            }) {
                                Label("Copy Image", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: saveImageToDisk) {
                                Label("Save PNG...", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("Type some text above to generate a QR Code.")
                            .foregroundColor(.secondary)
                            .padding(40)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }
            .padding(20)
        }
    }
    
    private func saveImageToDisk() {
        guard let img = qrImage,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "kobean-qrcode.png"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? png.write(to: url)
                appState.showToast("Saved QR Code to disk!")
            }
        }
    }
}
