//
//  WordBarApp.swift
//  WordBar
//
//  Created by yangqi on 2025/8/30.
//

import SwiftUI

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
    var isCurrentWord: Bool = false // 跟踪当前显示的是哪个单词
    var globalMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏按钮
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "vacant | 空的"
        }

        // 创建菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "切换单词", action: #selector(toggleWord), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        // 设置全局快捷键监听 (Option + `)
        setupGlobalHotkey()
    }

    func setupGlobalHotkey() {
        // 设置本地键盘监听器 (推荐方案)
        globalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // 检测 Option + ` 组合键
            if event.keyCode == 50 && event.modifierFlags.contains(.option) {
                self?.toggleWord()
                return nil // 消费事件，防止传递给其他应用
            }
            return event
        }
    }

    @objc func toggleWord() {
        if let button = statusItem.button {
            isCurrentWord.toggle()
            if isCurrentWord {
                button.title = "abandon | 放弃"
            } else {
                button.title = "vacant | 空的"
            }
        }
    }



    @objc func quit() {
        // 清理全局监听器
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NSApplication.shared.terminate(nil)
    }
}
