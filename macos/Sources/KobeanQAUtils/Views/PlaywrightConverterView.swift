import SwiftUI
import AppKit

struct PlaywrightConverterView: View {
    @EnvironmentObject private var appState: AppState
    
    enum ConversionDirection: String, CaseIterable, Identifiable {
        case playwrightToCodecept = "Playwright ➔ CodeceptJS"
        case codeceptToPlaywright = "CodeceptJS ➔ Playwright"
        var id: String { rawValue }
    }
    
    @State private var direction: ConversionDirection = .playwrightToCodecept
    @State private var inputCode: String = """
import { test, expect } from '@playwright/test';

test('User can submit feedback form', async ({ page }) => {
  await page.goto('https://example.com/feedback');
  await page.fill('#username', 'kobean_qa');
  await page.fill('#comments', 'Native macOS automation is lightning fast!');
  await page.click('button[type="submit"]');
  await expect(page.locator('.toast-success')).toBeVisible();
  await expect(page.locator('.toast-success')).toHaveText('Feedback sent');
});
"""
    @State private var convertedCode: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolHeaderView(tool: .playwrightConverter)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            // Toolbar
            HStack(spacing: 16) {
                Picker("Direction", selection: $direction) {
                    ForEach(ConversionDirection.allCases) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .frame(maxWidth: 280)
                .onChange(of: direction) { _ in convert() }
                
                Button("Sample Script") {
                    loadSample()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Clear") {
                    inputCode = ""
                    convertedCode = ""
                }
                .buttonStyle(.borderless)
                
                Button {
                    ClipboardHelper.copy(convertedCode)
                    appState.showToast("Copied converted test script")
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(convertedCode.isEmpty)
            }
            .padding(.horizontal, 24)
            
            // Dual Pane Editors
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(direction == .playwrightToCodecept ? "Playwright Script (JS/TS)" : "CodeceptJS Script (JS/TS)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $inputCode)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            .onChange(of: inputCode) { _ in convert() }
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                    
                    // Output
                    VStack(alignment: .leading, spacing: 6) {
                        Text(direction == .playwrightToCodecept ? "CodeceptJS Output" : "Playwright Output")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $convertedCode)
                            .font(.system(.body, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .frame(width: (geo.size.width - 16) / 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            convert()
        }
    }
    
    // MARK: - Translation Engine
    private func convert() {
        if direction == .playwrightToCodecept {
            convertedCode = translatePlaywrightToCodecept(inputCode)
        } else {
            convertedCode = translateCodeceptToPlaywright(inputCode)
        }
    }
    
    private func translatePlaywrightToCodecept(_ code: String) -> String {
        let lines = code.components(separatedBy: "\n")
        var result: [String] = []
        
        for line in lines {
            var l = line
            
            // test('title', ...) -> Scenario('title', ({ I }) => {
            if l.contains("test(") {
                l = l.replacingOccurrences(of: "test\\((['\"`][^'\"`]+['\"`]),\\s*async\\s*\\(\\{?\\s*page\\s*\\}?\\)\\s*=>", with: "Scenario($1, ({ I }) =>", options: .regularExpression)
            }
            // await page.goto(url) -> I.amOnPage(url)
            l = l.replacingOccurrences(of: "await\\s+page\\.goto\\(([^)]+)\\)", with: "I.amOnPage($1)", options: .regularExpression)
            // await page.fill(loc, val) -> I.fillField(loc, val)
            l = l.replacingOccurrences(of: "await\\s+page\\.fill\\(([^,]+),\\s*([^)]+)\\)", with: "I.fillField($1, $2)", options: .regularExpression)
            l = l.replacingOccurrences(of: "await\\s+page\\.type\\(([^,]+),\\s*([^)]+)\\)", with: "I.fillField($1, $2)", options: .regularExpression)
            // await page.locator(loc).fill(val) -> I.fillField(loc, val)
            l = l.replacingOccurrences(of: "await\\s+page\\.locator\\(([^)]+)\\)\\.fill\\(([^)]+)\\)", with: "I.fillField($1, $2)", options: .regularExpression)
            // await page.click(loc) -> I.click(loc)
            l = l.replacingOccurrences(of: "await\\s+page\\.click\\(([^)]+)\\)", with: "I.click($1)", options: .regularExpression)
            // await page.locator(loc).click() -> I.click(loc)
            l = l.replacingOccurrences(of: "await\\s+page\\.locator\\(([^)]+)\\)\\.click\\(\\)", with: "I.click($1)", options: .regularExpression)
            // await page.press(loc, key) -> I.pressKey(key)
            l = l.replacingOccurrences(of: "await\\s+page\\.press\\([^,]+,\\s*([^)]+)\\)", with: "I.pressKey($1)", options: .regularExpression)
            // await expect(page.locator(loc)).toBeVisible() -> I.seeElement(loc)
            l = l.replacingOccurrences(of: "await\\s+expect\\(page\\.locator\\(([^)]+)\\)\\)\\.toBeVisible\\(\\)", with: "I.seeElement($1)", options: .regularExpression)
            // await expect(page.locator(loc)).toHaveText(text) -> I.see(text, loc)
            l = l.replacingOccurrences(of: "await\\s+expect\\(page\\.locator\\(([^)]+)\\)\\)\\.toHaveText\\(([^)]+)\\)", with: "I.see($2, $1)", options: .regularExpression)
            // await page.waitForTimeout(ms) -> I.wait(sec)
            l = l.replacingOccurrences(of: "await\\s+page\\.waitForTimeout\\((\\d+)\\)", with: "I.wait($1 / 1000)", options: .regularExpression)
            // Strip @playwright/test import
            if l.contains("from '@playwright/test'") {
                continue
            }
            
            result.append(l)
        }
        
        return "Feature('Test Suite');\n\n" + result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func translateCodeceptToPlaywright(_ code: String) -> String {
        let lines = code.components(separatedBy: "\n")
        var result: [String] = []
        
        for line in lines {
            var l = line
            if l.contains("Feature(") { continue }
            // Scenario('title', ...) -> test('title', async ({ page }) => {
            if l.contains("Scenario(") {
                l = l.replacingOccurrences(of: "Scenario\\((['\"`][^'\"`]+['\"`]),\\s*\\(\\{\\s*I\\s*\\}\\)\\s*=>", with: "test($1, async ({ page }) =>", options: .regularExpression)
            }
            // I.amOnPage(url) -> await page.goto(url)
            l = l.replacingOccurrences(of: "I\\.amOnPage\\(([^)]+)\\)", with: "await page.goto($1)", options: .regularExpression)
            // I.click(loc) -> await page.click(loc)
            l = l.replacingOccurrences(of: "I\\.click\\(([^)]+)\\)", with: "await page.click($1)", options: .regularExpression)
            // I.fillField(loc, val) -> await page.fill(loc, val)
            l = l.replacingOccurrences(of: "I\\.fillField\\(([^,]+),\\s*([^)]+)\\)", with: "await page.fill($1, $2)", options: .regularExpression)
            // I.seeElement(loc) -> await expect(page.locator(loc)).toBeVisible()
            l = l.replacingOccurrences(of: "I\\.seeElement\\(([^)]+)\\)", with: "await expect(page.locator($1)).toBeVisible()", options: .regularExpression)
            // I.see(text, loc) -> await expect(page.locator(loc)).toHaveText(text)
            l = l.replacingOccurrences(of: "I\\.see\\(([^,]+),\\s*([^)]+)\\)", with: "await expect(page.locator($2)).toHaveText($1)", options: .regularExpression)
            
            result.append(l)
        }
        
        return "import { test, expect } from '@playwright/test';\n\n" + result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func loadSample() {
        if direction == .playwrightToCodecept {
            inputCode = """
import { test, expect } from '@playwright/test';

test('User login flow', async ({ page }) => {
  await page.goto('https://app.example.com/login');
  await page.fill('#email', 'tester@qa.org');
  await page.fill('#password', 'SecretPass2026!');
  await page.click('#btn-login');
  await expect(page.locator('.dashboard')).toBeVisible();
});
"""
        } else {
            inputCode = """
Feature('Authentication');

Scenario('User login flow', ({ I }) => {
  I.amOnPage('https://app.example.com/login');
  I.fillField('#email', 'tester@qa.org');
  I.fillField('#password', 'SecretPass2026!');
  I.click('#btn-login');
  I.seeElement('.dashboard');
});
"""
        }
        convert()
    }
}
