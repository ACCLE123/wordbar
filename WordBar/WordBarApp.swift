//
//  WordBarApp.swift
//  WordBar
//
//  Created by yangqi on 2025/8/30.
//

import SwiftUI
import AppKit

// MARK: - 数据结构
// Define the Word struct, conforming to Codable for JSON parsing
struct Word: Codable {
    var english: String
    var chinese: String
}

// MARK: - 辅助功能权限检查
// Check if accessibility permissions have been granted
func isTrusted() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

// MARK: - 应用主入口
@main
struct WordBarApp: App {
    // Create an application delegate to manage the status bar
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No window needed for a status bar application
        Settings {
            EmptyView()
        }
    }
}

// MARK: - 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    // An array to hold the words loaded from JSON
    var words: [Word] = []

    var currentWordIndex: Int = 0 // The current word index
    var globalMonitor: Any?
    var isShowingTranslation: Bool = false // Tracks if the Chinese translation is being displayed

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Load the word data from the JSON file
        loadWordsFromJSON()
        
        // If JSON loading fails, use a fallback word list
        if words.isEmpty {
            let backupWords = [
                ("vacant", "空的")
            ]
            words = backupWords.map { Word(english: $0.0, chinese: $0.1) }
        }
        
        // 2. Load the last word index from UserDefaults
        currentWordIndex = UserDefaults.standard.integer(forKey: "lastWordIndex")
        // Ensure the loaded index is within the bounds of the word array
        if currentWordIndex >= words.count {
            currentWordIndex = 0
        }
        
        // 3. Create the status bar button
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarTitle() // Initial display of the current word

        // 4. Create the menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "下一个单词 (⌃⌥→)", action: #selector(nextWord), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "上一个单词 (⌃⌥←)", action: #selector(previousWord), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        // 5. Check and set up the global hotkey listener
        setupGlobalHotkey()
        
        print("Application finished launching.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save the current word index to UserDefaults before the application terminates
        UserDefaults.standard.set(currentWordIndex, forKey: "lastWordIndex")
        print("📝 Application is about to terminate. Last word index \(currentWordIndex) has been saved.")
    }

    // MARK: - JSON Data Loading
    func loadWordsFromJSON() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            print("❌ Error: 'words.json' file not found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedWords = try JSONDecoder().decode([Word].self, from: data)
            self.words = decodedWords
            print("✅ Successfully loaded \(words.count) words from JSON file.")
        } catch {
            print("❌ JSON loading or parsing failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Core Functionality
    
    // Sets up the global hotkey listener
    func setupGlobalHotkey() {
        print("🚀 Setting up global keyboard listener...")
        
        if !isTrusted() {
            print("❌ Warning: 'Accessibility' or 'Input Monitoring' permissions not granted.")
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = "To enable global hotkeys, please go to 'System Settings' -> 'Privacy & Security' -> 'Accessibility' and grant permissions to WordBar."
            alert.runModal()
            return
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.control) &&
               event.modifierFlags.contains(.option) &&
               !event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.shift) {
                
                if event.keyCode == 124 { // Right Arrow
                    self?.nextWord()
                } else if event.keyCode == 123 { // Left Arrow
                    self?.previousWord()
                }
            }
        }
        
        if globalMonitor != nil {
            print("✅ Global listener successfully created!")
        } else {
            print("❌ Failed to create global listener!")
        }
    }

    // Updates the status bar title based on the current word and state
    func updateStatusBarTitle() {
        guard !words.isEmpty else {
            statusItem.button?.title = "No Words"
            return
        }
        
        if let button = statusItem.button {
            let currentWord = words[currentWordIndex]
            
            if isShowingTranslation {
                button.title = "\(currentWord.english) | \(currentWord.chinese)"
                print("📝 Word switched to: \(currentWord.english) | \(currentWord.chinese) (Index: \(currentWordIndex))")
            } else {
                button.title = "\(currentWord.english)"
                print("📝 Word switched to: \(currentWord.english) (Index: \(currentWordIndex))")
            }
        }
    }
    
    // Moves to the next word or reveals the translation
    @objc func nextWord() {
        guard !words.isEmpty else { return }
        
        if isShowingTranslation {
            currentWordIndex = (currentWordIndex + 1) % words.count
            isShowingTranslation = false
        } else {
            isShowingTranslation = true
        }
        updateStatusBarTitle()
    }

    // Moves to the previous word, always resetting to the English-only state
    @objc func previousWord() {
        guard !words.isEmpty else { return }
        
        currentWordIndex = (currentWordIndex - 1 + words.count) % words.count
        isShowingTranslation = false
        updateStatusBarTitle()
    }

    // Quits the application
    @objc func quit() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NSApplication.shared.terminate(nil)
    }
}
