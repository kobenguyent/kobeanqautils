import SwiftUI
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageTargetFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"
    case bmp = "BMP"
    
    var id: String { rawValue }
    
    var nsBitmapType: NSBitmapImageRep.FileType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .bmp: return .bmp
        }
    }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        }
    }
}

enum ImageFilterPreset: String, CaseIterable, Identifiable {
    case none = "None (Original)"
    case grayscale = "Grayscale (B&W)"
    case sepia = "Sepia Tone"
    case invert = "Invert Colors"
    
    var id: String { rawValue }
}

struct MediaConverterView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var sourceImage: NSImage? = nil
    @State private var previewImage: NSImage? = nil
    @State private var sourceFileName: String = ""
    @State private var sourceFileSize: Int = 0
    @State private var originalWidth: Int = 0
    @State private var originalHeight: Int = 0
    
    // Conversion parameters
    @State private var targetFormat: ImageTargetFormat = .png
    @State private var compressionQuality: Double = 0.85
    @State private var targetWidth: Int = 0
    @State private var targetHeight: Int = 0
    @State private var keepAspectRatio: Bool = true
    @State private var selectedFilter: ImageFilterPreset = .none
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .mediaConverter, onReset: resetToDefault)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            HSplitView {
                // Left: Controls & Adjustments
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // File Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Source Image")
                                .font(.headline)
                            
                            HStack {
                                Button(action: chooseImage) {
                                    Label("Open Image File...", systemImage: "photo.badge.plus")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                
                                Button(action: loadDemoImage) {
                                    Label("Load Demo", systemImage: "sparkles")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Spacer()
                            }
                            
                            if sourceImage != nil {
                                HStack(spacing: 12) {
                                    Text(sourceFileName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("\(originalWidth) × \(originalHeight) px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(formattedBytes(sourceFileSize))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                        
                        Divider()
                        
                        // Output Format
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Format")
                                .font(.headline)
                            
                            Picker("Format", selection: $targetFormat) {
                                ForEach(ImageTargetFormat.allCases) { fmt in
                                    Text(fmt.rawValue).tag(fmt)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: targetFormat) { _ in applyFiltersAndResize() }
                            
                            if targetFormat == .jpeg {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("JPEG Quality:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(compressionQuality * 100))%")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    Slider(value: $compressionQuality, in: 0.1...1.0, step: 0.05)
                                        .onChange(of: compressionQuality) { _ in applyFiltersAndResize() }
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        Divider()
                        
                        // Resize Dimensions
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Resize Dimensions")
                                    .font(.headline)
                                Spacer()
                                Toggle("Keep Aspect", isOn: $keepAspectRatio)
                                    .toggleStyle(.checkbox)
                                    .controlSize(.small)
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Width (px)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("Width", value: $targetWidth, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit { onWidthChanged() }
                                }
                                
                                Text("×")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 14)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Height (px)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("Height", value: $targetHeight, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit { onHeightChanged() }
                                }
                            }
                            
                            // Scale buttons
                            HStack(spacing: 6) {
                                scaleButton(25)
                                scaleButton(50)
                                scaleButton(75)
                                scaleButton(100)
                                scaleButton(150)
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                        
                        // Filter Effects
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image Filters & Effects")
                                .font(.headline)
                            
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(ImageFilterPreset.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.radioGroup)
                            .onChange(of: selectedFilter) { _ in applyFiltersAndResize() }
                        }
                        
                        Spacer()
                        
                        // Export Button
                        Button(action: saveConvertedImage) {
                            Label("Save Converted Image...", systemImage: "arrow.down.doc.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(sourceImage == nil || isProcessing)
                    }
                    .padding()
                }
                .frame(minWidth: 320, idealWidth: 360, maxWidth: 440)
                
                // Right: Live Image Preview
                VStack(spacing: 12) {
                    if let img = previewImage {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Live Converted Preview")
                                    .font(.headline)
                                Spacer()
                                Text("\(targetWidth) × \(targetHeight) px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            ZStack {
                                Color(NSColor.controlBackgroundColor)
                                
                                Image(nsImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(16)
                            }
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Image Loaded")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Open a PNG, JPEG, TIFF, or BMP image to convert, resize, or apply filters.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 280)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 400)
            }
        }
        .onAppear {
            if sourceImage == nil {
                loadDemoImage()
            }
        }
    }
    
    // MARK: - Image Operations
    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let img = NSImage(contentsOf: url),
               let rep = img.representations.first {
                sourceImage = img
                sourceFileName = url.lastPathComponent
                originalWidth = rep.pixelsWide > 0 ? rep.pixelsWide : Int(img.size.width)
                originalHeight = rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(img.size.height)
                targetWidth = originalWidth
                targetHeight = originalHeight
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int {
                    sourceFileSize = size
                }
                applyFiltersAndResize()
            }
        }
    }
    
    private func loadDemoImage() {
        // Load Brand Logo if available, or generate a canvas test icon
        if let brand = AppDelegate.loadBrandLogo() {
            sourceImage = brand
            sourceFileName = "AppLogo.png"
            let w = Int(brand.size.width)
            let h = Int(brand.size.height)
            originalWidth = w > 0 ? w : 256
            originalHeight = h > 0 ? h : 256
            targetWidth = originalWidth
            targetHeight = originalHeight
            sourceFileSize = 34500
            applyFiltersAndResize()
        }
    }
    
    private func onWidthChanged() {
        if keepAspectRatio && originalWidth > 0 {
            let ratio = Double(originalHeight) / Double(originalWidth)
            targetHeight = max(1, Int(Double(targetWidth) * ratio))
        }
        applyFiltersAndResize()
    }
    
    private func onHeightChanged() {
        if keepAspectRatio && originalHeight > 0 {
            let ratio = Double(originalWidth) / Double(originalHeight)
            targetWidth = max(1, Int(Double(targetHeight) * ratio))
        }
        applyFiltersAndResize()
    }
    
    @ViewBuilder
    private func scaleButton(_ pct: Int) -> some View {
        Button("\(pct)%") {
            targetWidth = max(1, Int(Double(originalWidth) * Double(pct) / 100.0))
            targetHeight = max(1, Int(Double(originalHeight) * Double(pct) / 100.0))
            applyFiltersAndResize()
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
    }
    
    private func applyFiltersAndResize() {
        guard let src = sourceImage else { return }
        
        var img = src
        
        // 1. Resize if dimensions changed
        if targetWidth > 0 && targetHeight > 0 && (targetWidth != originalWidth || targetHeight != originalHeight) {
            let newSize = NSSize(width: targetWidth, height: targetHeight)
            let resized = NSImage(size: newSize)
            resized.lockFocus()
            src.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: src.size), operation: .copy, fraction: 1.0)
            resized.unlockFocus()
            img = resized
        }
        
        // 2. Apply CoreImage filter if requested
        if selectedFilter != .none, let tiffData = img.tiffRepresentation, let ciImage = CIImage(data: tiffData) {
            var filtered: CIImage? = nil
            switch selectedFilter {
            case .none: break
            case .grayscale:
                let f = CIFilter.photoEffectMono()
                f.inputImage = ciImage
                filtered = f.outputImage
            case .sepia:
                let f = CIFilter.sepiaTone()
                f.inputImage = ciImage
                f.intensity = 0.85
                filtered = f.outputImage
            case .invert:
                let f = CIFilter.colorInvert()
                f.inputImage = ciImage
                filtered = f.outputImage
            }
            
            if let output = filtered {
                let rep = NSCIImageRep(ciImage: output)
                let filteredImg = NSImage(size: rep.size)
                filteredImg.addRepresentation(rep)
                img = filteredImg
            }
        }
        
        previewImage = img
    }
    
    private func saveConvertedImage() {
        guard let preview = previewImage else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: targetFormat.fileExtension)!]
        panel.nameFieldStringValue = "converted-\(sourceFileName.prefix(while: { $0 != "." })).\(targetFormat.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let tiff = preview.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff) {
                var props: [NSBitmapImageRep.PropertyKey: Any] = [:]
                if targetFormat == .jpeg {
                    props[.compressionFactor] = compressionQuality
                }
                if let data = rep.representation(using: targetFormat.nsBitmapType, properties: props) {
                    try? data.write(to: url)
                    appState.showToast("Saved converted image to \(url.lastPathComponent)")
                }
            }
        }
    }
    
    private func formattedBytes(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    private func resetToDefault() {
        targetFormat = .png
        compressionQuality = 0.85
        selectedFilter = .none
        targetWidth = originalWidth
        targetHeight = originalHeight
        applyFiltersAndResize()
    }
}
