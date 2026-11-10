import SwiftUI
import AppKit

struct ColorConverterView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var currentColor: Color = Color(red: 0.25, green: 0.45, blue: 0.85)
    @State private var hexInput: String = "#4073D9"
    @State private var redVal: Double = 64
    @State private var greenVal: Double = 115
    @State private var blueVal: Double = 217
    @State private var alphaVal: Double = 1.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .colorConverter)
                
                // Color Preview Card
                HStack(spacing: 20) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(currentColor)
                        .frame(width: 110, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            ColorPicker("Pick System Color", selection: $currentColor, supportsOpacity: true)
                                .font(.headline)
                                .onChange(of: currentColor) { newCol in
                                    syncFromColor(newCol)
                                }
                            Spacer()
                        }
                        
                        // WCAG Contrast
                        HStack(spacing: 12) {
                            contrastBadge(title: "vs White", ratio: contrastRatio(against: .white))
                            contrastBadge(title: "vs Black", ratio: contrastRatio(against: .black))
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // RGB Sliders
                VStack(alignment: .leading, spacing: 12) {
                    Text("RGB Sliders")
                        .font(.headline)
                    
                    colorSlider(label: "Red", value: $redVal, range: 0...255, tint: .red)
                    colorSlider(label: "Green", value: $greenVal, range: 0...255, tint: .green)
                    colorSlider(label: "Blue", value: $blueVal, range: 0...255, tint: .blue)
                    colorSlider(label: "Alpha", value: $alphaVal, range: 0...1, tint: .gray, isFloat: true)
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Formats Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color Formats & Code Export")
                        .font(.headline)
                    
                    formatRow(label: "HEX", value: hexString)
                    formatRow(label: "RGB", value: String(format: "rgb(%d, %d, %d)", Int(redVal), Int(greenVal), Int(blueVal)))
                    formatRow(label: "RGBA", value: String(format: "rgba(%d, %d, %d, %.2f)", Int(redVal), Int(greenVal), Int(blueVal), alphaVal))
                    formatRow(label: "HSL", value: hslString)
                    formatRow(label: "CMYK", value: cmykString)
                    formatRow(label: "SwiftUI", value: String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", redVal/255.0, greenVal/255.0, blueVal/255.0))
                    formatRow(label: "NSColor", value: String(format: "NSColor(srgbRed: %.3f, green: %.3f, blue: %.3f, alpha: %.2f)", redVal/255.0, greenVal/255.0, blueVal/255.0, alphaVal))
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            syncFromColor(currentColor)
        }
    }
    
    // MARK: - Components
    private func colorSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, tint: Color, isFloat: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .frame(width: 50, alignment: .leading)
            
            Slider(value: value, in: range)
                .tint(tint)
                .onChange(of: value.wrappedValue) { _ in
                    syncFromRGB()
                }
            
            Text(isFloat ? String(format: "%.2f", value.wrappedValue) : "\(Int(value.wrappedValue))")
                .font(.system(.subheadline, design: .monospaced))
                .frame(width: 45, alignment: .trailing)
        }
    }
    
    private func formatRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                ClipboardHelper.copy(value)
                appState.showToast("Copied \(label)")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy \(label)")
        }
        .padding(.vertical, 4)
    }
    
    private func contrastBadge(title: String, ratio: Double) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f:1", ratio))
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
            
            Text(ratio >= 7.0 ? "AAA" : (ratio >= 4.5 ? "AA" : "Fail"))
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(ratio >= 4.5 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundColor(ratio >= 4.5 ? .green : .red)
                .cornerRadius(4)
        }
    }
    
    // MARK: - Calculations
    private var hexString: String {
        String(format: "#%02X%02X%02X", Int(redVal), Int(greenVal), Int(blueVal))
    }
    
    private var hslString: String {
        let r = redVal / 255.0
        let g = greenVal / 255.0
        let b = blueVal / 255.0
        
        let maxV = max(r, max(g, b))
        let minV = min(r, min(g, b))
        let delta = maxV - minV
        
        var h: Double = 0
        var s: Double = 0
        let l: Double = (maxV + minV) / 2.0
        
        if delta > 0 {
            s = l > 0.5 ? delta / (2.0 - maxV - minV) : delta / (maxV + minV)
            if maxV == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if maxV == g {
                h = ((b - r) / delta) + 2.0
            } else {
                h = ((r - g) / delta) + 4.0
            }
            h *= 60.0
            if h < 0 { h += 360.0 }
        }
        return String(format: "hsl(%d, %d%%, %d%%)", Int(h), Int(s * 100), Int(l * 100))
    }
    
    private var cmykString: String {
        let r = redVal / 255.0
        let g = greenVal / 255.0
        let b = blueVal / 255.0
        let k = 1.0 - max(r, max(g, b))
        if k >= 1.0 {
            return "cmyk(0%, 0%, 0%, 100%)"
        }
        let c = (1.0 - r - k) / (1.0 - k)
        let m = (1.0 - g - k) / (1.0 - k)
        let y = (1.0 - b - k) / (1.0 - k)
        return String(format: "cmyk(%d%%, %d%%, %d%%, %d%%)", Int(c * 100), Int(m * 100), Int(y * 100), Int(k * 100))
    }
    
    private func syncFromRGB() {
        currentColor = Color(red: redVal / 255.0, green: greenVal / 255.0, blue: blueVal / 255.0, opacity: alphaVal)
    }
    
    private func syncFromColor(_ col: Color) {
        if let nsCol = NSColor(col).usingColorSpace(.sRGB) {
            redVal = Double(nsCol.redComponent * 255.0)
            greenVal = Double(nsCol.greenComponent * 255.0)
            blueVal = Double(nsCol.blueComponent * 255.0)
            alphaVal = Double(nsCol.alphaComponent)
        }
    }
    
    private func relativeLuminance(r: Double, g: Double, b: Double) -> Double {
        func adjust(_ c: Double) -> Double {
            let sc = c / 255.0
            return sc <= 0.03928 ? sc / 12.92 : pow((sc + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * adjust(r) + 0.7152 * adjust(g) + 0.0722 * adjust(b)
    }
    
    private func contrastRatio(against bg: Color) -> Double {
        let l1 = relativeLuminance(r: redVal, g: greenVal, b: blueVal)
        let l2 = bg == .white ? 1.0 : 0.0
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
