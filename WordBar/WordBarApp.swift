//
//  WordBarApp.swift
//  WordBar
//
//  Created by yangqi on 2025/8/30.
//

import SwiftUI
import AppKit

// 检查是否获得了辅助功能权限
func isTrusted() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

@main
struct WordBarApp: App {
    // 创建一个控制器管理状态栏
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 没有界面，不需要窗口
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    // 单词库
    let words = [
        ("vacant", "空的"),
        ("abandon", "放弃"),
        ("brilliant", "辉煌的"),
        ("curious", "好奇的"),
        ("diligent", "勤奋的"),
        ("elegant", "优雅的"),
        ("fabulous", "极好的"),
        ("grateful", "感激的"),
        ("hilarious", "搞笑的"),
        ("intelligent", "聪明的")
    ]

    var currentWordIndex: Int = 0 // 当前单词索引
    var globalMonitor: Any?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏按钮
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarTitle()

        // 创建菜单
        let menu = NSMenu()
        // 更新菜单项，添加新的快捷键提示
        menu.addItem(NSMenuItem(title: "下一个单词 (⌃⌥→)", action: #selector(nextWord), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "上一个单词 (⌃⌥←)", action: #selector(previousWord), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        // 检查并设置全局快捷键监听器
        setupGlobalHotkey()
        
        print("应用启动完成")
    }
    
    // 设置全局快捷键监听器
    func setupGlobalHotkey() {
        print("🚀 开始设置全局键盘监听器...")
        
        // 检查是否已获得辅助功能权限
        if !isTrusted() {
            print("❌ 警告：未获得 '辅助功能' 或 '输入监听' 权限。")
            print("💡 请前往 '系统设置' -> '隐私与安全性' -> '辅助功能'，为 WordBar 授权。")
            // 这里可以添加一个简单的弹窗提示用户
            let alert = NSAlert()
            alert.messageText = "需要权限"
            alert.informativeText = "为了使全局快捷键生效，请前往“系统设置” -> “隐私与安全性” -> “辅助功能”，为 WordBar 授权。"
            alert.runModal()
            return
        }

        // ⚠️ 使用 addGlobalMonitorForEvents 恢复全局监听功能。
        // 这将使快捷键在应用非活跃时也可用，但会再次输出对应的字符。
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // 检查组合键是否包含 Control 和 Option
            if event.modifierFlags.contains(.control) &&
               event.modifierFlags.contains(.option) &&
               !event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.shift) {
                
                // 检查按键是否为右箭头或左箭头
                if event.keyCode == 124 { // 右箭头
                    self?.nextWord()
                } else if event.keyCode == 123 { // 左箭头
                    self?.previousWord()
                }
            }
        }
        
        // 检查监听器是否创建成功
        if globalMonitor != nil {
            print("✅ 全局监听器创建成功!")
            print("💡 快捷键 Option + 9 和 Option + 0 已启用")
        } else {
            print("❌ 全局监听器创建失败!")
        }
    }

    // 更新状态栏标题
    func updateStatusBarTitle() {
        if let button = statusItem.button {
            let (english, chinese) = words[currentWordIndex]
            button.title = "\(english) | \(chinese)"
            print("📝 单词已切换到: \(english) | \(chinese) (索引: \(currentWordIndex))")
        }
    }
    
    // 下一个单词
    @objc func nextWord() {
        currentWordIndex = (currentWordIndex + 1) % words.count
        updateStatusBarTitle()
    }

    // 上一个单词
    @objc func previousWord() {
        currentWordIndex = (currentWordIndex - 1 + words.count) % words.count
        updateStatusBarTitle()
    }

    @objc func quit() {
        // 清理全局监听器
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NSApplication.shared.terminate(nil)
    }
}
