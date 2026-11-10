import SwiftUI
import AppKit

struct RecommendedModel: Identifiable {
    let id = UUID()
    let name: String
    let parameters: String
    let quant: String
    let vram: String
    let speed: String
    let useCase: String
    let command: String
}

struct LocalLLMGuideView: View {
    @EnvironmentObject private var appState: AppState
    
    // Interactive Estimator
    @State private var modelParams: Double = 8.0 // 8B parameters
    @State private var quantBits: Double = 4.0   // 4-bit (Q4_K_M)
    @State private var contextLength: Double = 8192 // 8k context
    @State private var macRam: Int = 16 // 16GB
    
    let macRamOptions = [8, 16, 24, 36, 48, 64, 128]
    
    let models16GB: [RecommendedModel] = [
        RecommendedModel(
            name: "Llama 3.2 3B",
            parameters: "3.2B",
            quant: "Q4_K_M",
            vram: "2.4 GB",
            speed: "~65 tok/s",
            useCase: "Ultra-fast code completion, summaries, testing assertions",
            command: "ollama run llama3.2:3b"
        ),
        RecommendedModel(
            name: "Qwen 2.5 Coder 7B",
            parameters: "7.6B",
            quant: "Q4_K_M",
            vram: "4.8 GB",
            speed: "~35 tok/s",
            useCase: "Premier local coding assistant (Python, TypeScript, Swift, SQL)",
            command: "ollama run qwen2.5-coder:7b"
        ),
        RecommendedModel(
            name: "DeepSeek Coder 6.7B",
            parameters: "6.7B",
            quant: "Q5_K_M",
            vram: "5.1 GB",
            speed: "~38 tok/s",
            useCase: "Unit test generation, regex building, bug debugging",
            command: "ollama run deepseek-coder:6.7b"
        ),
        RecommendedModel(
            name: "Llama 3.1 8B",
            parameters: "8.0B",
            quant: "Q4_K_M",
            vram: "5.5 GB",
            speed: "~32 tok/s",
            useCase: "General QA reasoning, test scenario extraction, documentation",
            command: "ollama run llama3.1:8b"
        ),
        RecommendedModel(
            name: "Mistral NeMo 12B",
            parameters: "12.2B",
            quant: "Q4_K_M",
            vram: "7.8 GB",
            speed: "~22 tok/s",
            useCase: "High accuracy multi-turn reasoning with 128k context support",
            command: "ollama run mistral-nemo:12b"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ToolHeaderView(tool: .localLlmGuide, onReset: resetEstimator)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Apple Silicon Architecture Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                                .foregroundColor(.primary)
                            Text("Apple Silicon Unified Memory (UMA)")
                                .font(.headline)
                        }
                        
                        Text("On M-series chips (M1–M4), CPU, GPU, and Neural Engine share the exact same high-bandwidth memory pool (up to 400+ GB/s). Model weights stay directly in unified RAM with zero PCIe transfer penalties. macOS dynamically allocates up to 75% of physical RAM to GPU Metal pipelines.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Interactive RAM & VRAM Estimator
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Interactive VRAM & Memory Estimator", systemImage: "gauge.with.needle")
                                .font(.headline)
                            Spacer()
                            
                            Picker("Target Mac RAM", selection: $macRam) {
                                ForEach(macRamOptions, id: \.self) { ram in
                                    Text("\(ram) GB").tag(ram)
                                }
                            }
                            .frame(width: 130)
                        }
                        
                        VStack(spacing: 12) {
                            // Model Size Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Model Parameters:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f Billion (%.0fB)", modelParams, modelParams))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                Slider(value: $modelParams, in: 1...70, step: 1)
                            }
                            
                            // Quantization Bits Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Quantization:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(quantLabel(quantBits))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                Slider(value: $quantBits, in: 2...16, step: 1)
                            }
                            
                            // Context Window Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Context Window:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(contextLength)) tokens")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                Slider(value: $contextLength, in: 2048...32768, step: 2048)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Calculated Results
                        HStack(spacing: 12) {
                            statBox(title: "MODEL WEIGHTS", value: String(format: "%.1f GB", weightsSizeGB), color: .blue)
                            statBox(title: "KV CACHE", value: String(format: "%.1f GB", kvCacheGB), color: .purple)
                            statBox(title: "TOTAL VRAM REQUIRED", value: String(format: "%.1f GB", totalVramRequired), color: canRunOnMac ? .green : .red)
                            statBox(title: "MAC COMPATIBILITY", value: canRunOnMac ? "✅ Fits in \(macRam)GB" : "⚠️ Exceeds \(macRam)GB", color: canRunOnMac ? .green : .red)
                        }
                    }
                    
                    // Recommended Models for 16GB
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Top Local Models for Apple Silicon", systemImage: "star.fill")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            ForEach(models16GB) { model in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(model.name)
                                                .font(.headline)
                                            
                                            Text(model.quant)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.accentColor.opacity(0.15))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(4)
                                            
                                            Text(model.speed)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text(model.useCase)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(model.command)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(6)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(NSColor.textBackgroundColor))
                                            .cornerRadius(4)
                                    }
                                    
                                    Button(action: {
                                        ClipboardHelper.copy(model.command)
                                        appState.showToast("Command copied: \(model.command)")
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .help("Copy command")
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Ollama & MLX Environment Configs
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Production Ollama & MLX Performance Flags", systemImage: "terminal.fill")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            configSnippet(
                                title: "Enable Apple Metal Flash Attention in Ollama",
                                snippet: "export OLLAMA_FLASH_ATTENTION=1\nexport OLLAMA_NUM_PARALLEL=4\nollama serve"
                            )
                            
                            configSnippet(
                                title: "Apple MLX Framework (Zero-copy Python runtime)",
                                snippet: "pip install mlx-lm\npython -m mlx_lm.generate --model mlx-community/Qwen2.5-Coder-7B-Instruct-4bit --prompt 'Write a Playwright test'"
                            )
                            
                            configSnippet(
                                title: "Check Real-time GPU & Unified Memory Usage",
                                snippet: "sudo powermetrics --samplers gpu_power,thermal -i 1000\nvm_stat"
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Calculations
    private var weightsSizeGB: Double {
        // params in billions * (bits / 8) * 1.05 overhead
        (modelParams * 1_000_000_000 * (quantBits / 8.0) * 1.05) / 1_073_741_824
    }
    
    private var kvCacheGB: Double {
        // Rough estimate for context: 2 * layers * heads * dim * context
        // for 8B model: ~0.5 GB per 8k context
        (contextLength / 8192.0) * (modelParams / 8.0) * 0.75
    }
    
    private var totalVramRequired: Double {
        weightsSizeGB + kvCacheGB + 0.5 // 0.5 GB runtime context
    }
    
    private var canRunOnMac: Bool {
        // macOS allows ~75% of physical RAM for GPU Metal allocation
        let usableVram = Double(macRam) * 0.75
        return totalVramRequired <= usableVram
    }
    
    private func quantLabel(_ bits: Double) -> String {
        switch Int(bits) {
        case 2: return "2-bit (Q2_K - Extreme loss)"
        case 3: return "3-bit (Q3_K_M - High compression)"
        case 4: return "4-bit (Q4_K_M - Recommended balance)"
        case 5: return "5-bit (Q5_K_M - Near-lossless)"
        case 6: return "6-bit (Q6_K - Very sharp)"
        case 8: return "8-bit (Q8_0 - Unquantized precision)"
        case 16: return "16-bit (FP16 - Full weights)"
        default: return "\(Int(bits))-bit"
        }
    }
    
    // MARK: - UI Helpers
    @ViewBuilder
    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func configSnippet(title: String, snippet: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    ClipboardHelper.copy(snippet)
                    appState.showToast("Copied script")
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text(snippet)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
    }
    
    private func resetEstimator() {
        modelParams = 8.0
        quantBits = 4.0
        contextLength = 8192
        macRam = 16
    }
}
