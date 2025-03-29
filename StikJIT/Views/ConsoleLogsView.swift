//
//  ConsoleLogsView.swift
//  StikJIT
//
//  Created by neoarz on 3/29/25.
//

import SwiftUI
import UIKit

struct ConsoleLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logManager = LogManager.shared
    @State private var autoScroll = true
    @State private var scrollView: ScrollViewProxy? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Terminal-style logs area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Device Information
                                ForEach(["Version: \(UIDevice.current.systemVersion)",
                                         "Name: \(UIDevice.current.name)",
                                         "Model: \(UIDevice.current.model)",
                                         "StikJIT Version: App Version: 1.0"], id: \.self) { info in
                                    Text("[\(timeString())] ℹ️ \(info)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 4)
                                }
                                
                                Spacer()
                                
                                // Log entries with terminal-style alignment (no indentation on wrapped lines)
                                ForEach(logManager.logs) { logEntry in
                                    Text(AttributedString(createLogAttributedString(logEntry)))
                                        .font(.system(size: 11, design: .monospaced))
                                        .textSelection(.enabled)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 1)
                                        .padding(.horizontal, 4)
                                        .id(logEntry.id)
                                }
                            }
                        }
                        .onAppear {
                            scrollView = proxy
                        }
                        .onChange(of: logManager.logs.count) {
                            if autoScroll, let lastLog = logManager.logs.last {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom section with error count and action buttons
                    VStack(spacing: 16) {
                        // Error count with red theme
                        HStack {
                            Text("\(logManager.errorCount) Critical Errors.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Action buttons with dark background
                        VStack(spacing: 1) {
                            // Share button
                            Button(action: {
                                let logs = logManager.logs.map { "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" }.joined(separator: "\n")
                                
                                // Create a temporary file for the logs
                                let tempDirectoryURL = FileManager.default.temporaryDirectory
                                let tempFileURL = tempDirectoryURL.appendingPathComponent("StikJIT_Logs_\(Date().timeIntervalSince1970).txt")
                                
                                do {
                                    try logs.write(to: tempFileURL, atomically: true, encoding: .utf8)
                                    
                                    // Share the file instead of just the text
                                    let activityVC = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
                                    
                                    // Present the view controller
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = windowScene.windows.first?.rootViewController {
                                        
                                        // For iPad, we need to specify the source view and source rect
                                        if let popoverController = activityVC.popoverPresentationController {
                                            popoverController.sourceView = rootVC.view
                                            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                                            popoverController.permittedArrowDirections = []
                                        }
                                        
                                        rootVC.present(activityVC, animated: true)
                                    }
                                } catch {
                                    print("Error writing logs to file: \(error)")
                                }
                            }) {
                                HStack {
                                    Text("Share Logs")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Copy button
                            Button(action: {
                                let logs = logManager.logs.map { "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" }.joined(separator: "\n")
                                UIPasteboard.general.string = logs
                            }) {
                                HStack {
                                    Text("Copy Logs")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        }
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Console Logs")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Settings")
                                .fontWeight(.regular)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        logManager.clearLogs()
                    }) {
                        Text("Clear")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Creates an NSAttributedString that combines timestamp, type, and message
    // with proper styling for each component
    private func createLogAttributedString(_ logEntry: LogManager.LogEntry) -> NSAttributedString {
        let fullString = NSMutableAttributedString()
        
        // Timestamp part
        let timestampString = "[\(formatTime(date: logEntry.timestamp))]"
        let timestampAttr = NSAttributedString(
            string: timestampString,
            attributes: [.foregroundColor: UIColor.gray]
        )
        fullString.append(timestampAttr)
        fullString.append(NSAttributedString(string: " "))
        
        // Log type part
        let typeString = "[\(logEntry.type.rawValue)]"
        let typeColor = UIColor(colorForLogType(logEntry.type))
        let typeAttr = NSAttributedString(
            string: typeString,
            attributes: [.foregroundColor: typeColor]
        )
        fullString.append(typeAttr)
        fullString.append(NSAttributedString(string: " "))
        
        // Message part
        let messageAttr = NSAttributedString(
            string: logEntry.message,
            attributes: [.foregroundColor: UIColor.white]
        )
        fullString.append(messageAttr)
        
        return fullString
    }
    
    // Helper to display current time
    private func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // Helper to format Date objects to time strings
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // Return color based on log type
    private func colorForLogType(_ type: LogManager.LogEntry.LogType) -> Color {
        switch type {
        case .info:
            return .green
        case .error:
            return .red
        case .debug:
            return .blue
        case .warning:
            return .orange
        }
    }
}

// Preview provider
struct ConsoleLogsView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleLogsView()
    }
} 