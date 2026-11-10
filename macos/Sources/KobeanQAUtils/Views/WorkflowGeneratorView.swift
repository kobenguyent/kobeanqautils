import SwiftUI
import AppKit

struct WorkflowGeneratorView: View {
    @EnvironmentObject private var appState: AppState
    
    enum PipelinePlatform: String, CaseIterable, Identifiable {
        case github = "GitHub Actions"
        case gitlab = "GitLab CI"
        case jenkins = "Jenkinsfile"
        var id: String { rawValue }
        
        var defaultFilename: String {
            switch self {
            case .github: return "ci.yml"
            case .gitlab: return ".gitlab-ci.yml"
            case .jenkins: return "Jenkinsfile"
            }
        }
    }
    
    enum RuntimeEnv: String, CaseIterable, Identifiable {
        case node20 = "Node.js 20 (LTS)"
        case node22 = "Node.js 22"
        case python312 = "Python 3.12"
        case java21 = "Java 21 (Maven)"
        case golang = "Go 1.23"
        var id: String { rawValue }
    }
    
    enum TestRunner: String, CaseIterable, Identifiable {
        case playwright = "Playwright"
        case vitest = "Vitest / Jest"
        case cypress = "Cypress"
        case pytest = "Pytest"
        var id: String { rawValue }
    }
    
    @State private var platform: PipelinePlatform = .github
    @State private var runtime: RuntimeEnv = .node20
    @State private var testRunner: TestRunner = .playwright
    @State private var runLint: Bool = true
    @State private var uploadArtifacts: Bool = true
    @State private var enableCaching: Bool = true
    @State private var targetBranch: String = "main"
    @State private var workflowContent: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolHeaderView(tool: .workflowGen)
                
                // Config Box
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CI/CD Platform")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $platform) {
                                ForEach(PipelinePlatform.allCases) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            .onChange(of: platform) { _ in generate() }
                        }
                        .frame(maxWidth: 200)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Runtime Environment")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $runtime) {
                                ForEach(RuntimeEnv.allCases) { r in
                                    Text(r.rawValue).tag(r)
                                }
                            }
                            .onChange(of: runtime) { _ in generate() }
                        }
                        .frame(maxWidth: 200)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Test Suite")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("", selection: $testRunner) {
                                ForEach(TestRunner.allCases) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .onChange(of: testRunner) { _ in generate() }
                        }
                        .frame(maxWidth: 180)
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Run Linter", isOn: $runLint)
                            .toggleStyle(.checkbox)
                            .onChange(of: runLint) { _ in generate() }
                        
                        Toggle("Dependency Cache", isOn: $enableCaching)
                            .toggleStyle(.checkbox)
                            .onChange(of: enableCaching) { _ in generate() }
                        
                        Toggle("Upload Test Artifacts", isOn: $uploadArtifacts)
                            .toggleStyle(.checkbox)
                            .onChange(of: uploadArtifacts) { _ in generate() }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                
                // Output Toolbar
                HStack {
                    Text(platform.defaultFilename)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        saveToFile()
                    } label: {
                        Label("Save File...", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        ClipboardHelper.copy(workflowContent)
                        appState.showToast("Copied CI/CD workflow configuration")
                    } label: {
                        Label("Copy YAML", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Output Editor
                TextEditor(text: $workflowContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 380)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .padding(24)
        }
        .onAppear {
            generate()
        }
    }
    
    // MARK: - Generation Logic
    private func generate() {
        switch platform {
        case .github:
            workflowContent = generateGitHubActions()
        case .gitlab:
            workflowContent = generateGitLabCI()
        case .jenkins:
            workflowContent = generateJenkinsfile()
        }
    }
    
    private func generateGitHubActions() -> String {
        var steps: [String] = []
        steps.append("      - name: Checkout repository\n        uses: actions/checkout@v4")
        
        switch runtime {
        case .node20, .node22:
            let v = runtime == .node20 ? "20" : "22"
            steps.append("      - name: Setup Node.js \(v)\n        uses: actions/setup-node@v4\n        with:\n          node-version: '\(v)'\(enableCaching ? "\n          cache: 'npm'" : "")")
            steps.append("      - name: Install dependencies\n        run: npm ci")
            if runLint {
                steps.append("      - name: Run ESLint\n        run: npm run lint")
            }
            if testRunner == .playwright {
                steps.append("      - name: Install Playwright Browsers\n        run: npx playwright install --with-deps")
                steps.append("      - name: Run Playwright Tests\n        run: npx playwright test")
            } else {
                steps.append("      - name: Run Test Suite\n        run: npm test")
            }
        case .python312:
            steps.append("      - name: Setup Python 3.12\n        uses: actions/setup-python@v5\n        with:\n          python-version: '3.12'\(enableCaching ? "\n          cache: 'pip'" : "")")
            steps.append("      - name: Install dependencies\n        run: pip install -r requirements.txt")
            if runLint {
                steps.append("      - name: Run Flake8 / Ruff\n        run: ruff check .")
            }
            steps.append("      - name: Run Pytest\n        run: pytest --maxfail=5 -rf")
        default:
            steps.append("      - name: Setup Language Toolchain\n        run: echo 'Configured'")
            steps.append("      - name: Run Tests\n        run: make test")
        }
        
        if uploadArtifacts {
            steps.append("      - name: Upload Test Report & Traces\n        if: always()\n        uses: actions/upload-artifact@v4\n        with:\n          name: test-results\n          path: | \n            playwright-report/\n            test-results/\n          retention-days: 14")
        }
        
        return """
name: CI & Automated QA Test Pipeline

on:
  push:
    branches: [ \(targetBranch) ]
  pull_request:
    branches: [ \(targetBranch) ]

jobs:
  test:
    name: Run Automated Quality Checks
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
\(steps.joined(separator: "\n\n"))
"""
    }
    
    private func generateGitLabCI() -> String {
        return """
stages:
  - lint
  - test
  - report

variables:
  NODE_ENV: 'test'

default:
  image: node:20-bullseye

lint:
  stage: lint
  script:
    - npm ci
    - npm run lint
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "\(targetBranch)"

test:
  stage: test
  script:
    - npm ci
    - npx playwright install --with-deps
    - npm test
  artifacts:
    when: always
    paths:
      - test-results/
      - playwright-report/
    expire_in: 14 days
"""
    }
    
    private func generateJenkinsfile() -> String {
        return """
pipeline {
    agent {
        docker {
            image 'node:20-bullseye'
            args '-u root'
        }
    }
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'test-results/**, playwright-report/**', allowEmptyArchive: true
        }
    }
}
"""
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = platform.defaultFilename
        if panel.runModal() == .OK, let url = panel.url {
            try? workflowContent.write(to: url, atomically: true, encoding: .utf8)
            appState.showToast("Saved workflow to \(url.lastPathComponent)")
        }
    }
}
