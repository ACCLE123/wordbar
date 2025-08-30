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
    var isShowingTranslation: Bool = false // 新增状态变量，追踪是否显示中文释义

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏按钮
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarTitle() // 初始只显示英文

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
        } else {
            print("❌ 全局监听器创建失败!")
        }
    }

    // 更新状态栏标题
    func updateStatusBarTitle() {
        if let button = statusItem.button {
            let (english, chinese) = words[currentWordIndex]
            
            // 根据 isShowingTranslation 决定显示内容
            if isShowingTranslation {
                button.title = "\(english) | \(chinese)"
                print("📝 单词已切换到: \(english) | \(chinese) (索引: \(currentWordIndex))")
            } else {
                button.title = "\(english)"
                print("📝 单词已切换到: \(english) (索引: \(currentWordIndex))")
            }
        }
    }
    
    // 下一个单词或显示释义
    @objc func nextWord() {
        if isShowingTranslation {
            // 如果已显示释义，则前进到下一个单词
            currentWordIndex = (currentWordIndex + 1) % words.count
            isShowingTranslation = false // 重置为只显示英文
        } else {
            // 如果只显示英文，则切换为显示中英文
            isShowingTranslation = true
        }
        updateStatusBarTitle()
    }

    // 上一个单词，始终退回到英文状态
    @objc func previousWord() {
        currentWordIndex = (currentWordIndex - 1 + words.count) % words.count
        isShowingTranslation = false // 始终重置为只显示英文
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
