//  SettingsView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.

import SwiftUI
import UniformTypeIdentifiers

// Add this if ConsoleLogsView is in a different module (unlikely but just in case)
// import ConsoleLogsModule 

struct SettingsView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @AppStorage("selectedAppIcon") private var selectedAppIcon: String = "AppIcon"
    @State private var isShowingPairingFilePicker = false

    @State private var selectedBackgroundColor: Color = Color.primaryBackground
    @State private var showIconPopover = false
    @State private var showPairingFileMessage = false
    @State private var pairingFileIsValid = false
    @State private var isImportingFile = false
    @State private var importProgress: Float = 0.0
    
    @StateObject private var mountProg = MountingProgress.shared
    
    @State private var mounted = false
    
    @State private var showingConsoleLogsView = false
    
    // Developer profile image URLs 
    private let developerProfiles: [String: String] = [
        "Blu": "https://github.com/0-Blu.png",
        "jkcoxson": "https://github.com/jkcoxson.png",
        "Stossy11": "https://github.com/Stossy11.png",
        "Neo": "https://github.com/neoarz.png",
        "Se2crid": "https://github.com/Se2crid.png",
        "HugeBlack": "https://github.com/HugeBlack.png"
    ]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // App Logo and Username Section 
                    VStack(spacing: 16) {
                        // App Logo
                        Image(uiImage: UIImage(named: selectedAppIcon) ?? UIImage(named: "AppIcon") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.top, 16)
                        
                        Text("StikJIT")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Username", text: $username)
                                .padding(14)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.6)
                    
                    // Appearance section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            ColorPicker("Background Color", selection: $selectedBackgroundColor)
                                .onChange(of: selectedBackgroundColor) { newColor in
                                    saveCustomBackgroundColor(newColor)
                                }
                                .foregroundColor(.primary)
                                .padding(.vertical, 6)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    
                    // Pairing File section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Pairing File")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Button {
                                isShowingPairingFilePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Import New Pairing File")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            if isImportingFile {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Processing pairing file...")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(importProgress * 100))%")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(height: 10)
                                            
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width * CGFloat(importProgress), height: 10)
                                                .animation(.linear(duration: 0.3), value: importProgress)
                                        }
                                    }
                                    .frame(height: 10)
                                }
                                .padding(.top, 6)
                            }
                            
                            if showPairingFileMessage && pairingFileIsValid {
                                HStack {
                                    Spacer()
                                    Text("✓ Pairing file successfully imported")
                                        .font(.system(.callout, design: .rounded))
                                        .foregroundColor(.green)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                                .padding(.top, 6)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.9)
                                            .combined(with: .opacity)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7)),
                                        removal: .opacity.animation(.easeOut(duration: 0.25))
                                    )
                                )
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    
                    // Developer Disk Image section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Developer Disk Image")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Status indicator with icon
                            HStack(spacing: 12) {
                                Image(systemName: mounted || (mountProg.mountProgress == 100) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(mounted || (mountProg.mountProgress == 100) ? .green : .red)
                                
                                Text(mounted || (mountProg.mountProgress == 100) ? "Successfully Mounted" : "Not Mounted")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                            
                            // Helper text shown separately below the status indicator
                            if !(mounted || (mountProg.mountProgress == 100)) {
                                Text("Import pairing file and restart the app to mount DDI")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                            
                            // Only show progress if actively mounting
                            if mountProg.mountProgress > 0 && mountProg.mountProgress < 100 && !mounted {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Mounting in progress...")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(mountProg.mountProgress))%")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width * CGFloat(mountProg.mountProgress / 100.0), height: 8)
                                                .animation(.linear(duration: 0.3), value: mountProg.mountProgress)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding(.top, 6)
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .onAppear() {
                            self.mounted = isMounted()
                        }
                    }
                    
                    
                    // About section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Main Developers 
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Developers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                              
                                HStack(spacing: 16) {
                                    // App Creator
                                    VStack(spacing: 8) {
                                        ProfileImage(url: developerProfiles["Blu"] ?? "")
                                            .frame(width: 60, height: 60)
                                        
                                        Text("Blu")
                                            .fontWeight(.semibold)
                                        
                                        Text("App Creator")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        if let url = URL(string: "https://github.com/0-Blu") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    
                                    // Library Developer
                                    VStack(spacing: 8) {
                                        ProfileImage(url: developerProfiles["jkcoxson"] ?? "")
                                            .frame(width: 60, height: 60)
                                        
                                        Text("jkcoxson")
                                            .fontWeight(.semibold)
                                        
                                        Text("idevice & em_proxy")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        if let url = URL(string: "https://jkcoxson.com/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Collaborators in vertical stack
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Collaborators")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Vertical stack of collaborators
                                VStack(spacing: 12) {
                                    CollaboratorRow(name: "Stossy11", url: "https://github.com/Stossy11", imageUrl: developerProfiles["Stossy11"] ?? "")
                                    
                                    CollaboratorRow(name: "Neo", url: "https://neoarz.xyz/", imageUrl: developerProfiles["Neo"] ?? "")
                                    
                                    CollaboratorRow(name: "Se2crid", url: "https://github.com/Se2crid", imageUrl: developerProfiles["Se2crid"] ?? "")
                                    
                                    CollaboratorRow(name: "HugeBlack", url: "https://github.com/HugeBlack", imageUrl: developerProfiles["HugeBlack"] ?? "")
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Links")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 6) {
                                    LinkRow(icon: "link", title: "Source Code", url: "https://github.com/0-Blu/StikJIT")
                                    LinkRow(icon: "xmark.shield", title: "Report an Issue", url: "https://github.com/0-Blu/StikJIT/issues")
                                    
                                    // StikNES promotion - moved here as requested
                                    Button(action: {
                                        if let url = URL(string: "https://apps.apple.com/us/app/stiknes/id6737158545") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Text("Like this app? Check out StikNES!")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Image(systemName: "gamecontroller.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                    
                    // Move System Logs section here (right after About card, before version)
                    SettingsCard {
                        Button(action: {
                            showingConsoleLogsView = true
                        }) {
                            HStack {
                                Text("System Logs")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 16)
                    
                    // Version info should now come after System Logs
                    HStack {
                        Spacer()
                        Text("Version 1.0 • iOS \(UIDevice.current.systemVersion)")
                            .font(.footnote)
                            .foregroundColor(.secondary.opacity(0.8))
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            
            // Add this sheet at the end of the ZStack, before the final closing bracket
            .sheet(isPresented: $showingConsoleLogsView) {
                ConsoleLogsView()
            }
        }
        .fileImporter(
            isPresented: $isShowingPairingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                // Get the first URL from the array
                guard let url = urls.first else { return }
                
                let fileManager = FileManager.default
                let accessing = url.startAccessingSecurityScopedResource()
                
                if fileManager.fileExists(atPath: url.path) {
                    do {
                        if fileManager.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            try fileManager.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        }
                        
                        try fileManager.copyItem(at: url, to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        print("File copied successfully!")
                        
                        // Show progress bar and initialize progress
                        DispatchQueue.main.async {
                            isImportingFile = true
                            importProgress = 0.0
                            pairingFileIsValid = false
                        }
                        
                        // Create timer to update progress 
                        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                            DispatchQueue.main.async {
                                if importProgress < 1.0 {
                                    importProgress += 0.05
                                } else {
                                    timer.invalidate()
                                    isImportingFile = false
                                    pairingFileIsValid = true
                                    
                                    // Show success message
                                    withAnimation {
                                        showPairingFileMessage = true
                                    }
                                    
                                    // Hide message after delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            showPairingFileMessage = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Ensure timer keeps running
                        RunLoop.current.add(progressTimer, forMode: .common)
                        
                        // Start heartbeat in background
                        startHeartbeatInBackground()
                        
                    } catch {
                        print("Error copying file: \(error)")
                    }
                } else {
                    print("Source file does not exist.")
                }
                
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Failed to import file: \(error)")
            }
        }
        .onAppear {
            loadCustomBackgroundColor()
        }
    }

    private func loadCustomBackgroundColor() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }

    private func saveCustomBackgroundColor(_ color: Color) {
        customBackgroundColorHex = color.toHex() ?? "#000000"
    }

    private func changeAppIcon(to iconName: String) {
        selectedAppIcon = iconName
        UIApplication.shared.setAlternateIconName(iconName == "AppIcon" ? nil : iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
    }

    private func iconButton(_ label: String, icon: String) -> some View {
        Button(action: {
            changeAppIcon(to: icon)
            showIconPopover = false
        }) {
            HStack {
                Image(uiImage: UIImage(named: icon) ?? UIImage())
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// Helper components
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
}

struct InfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct LinkRow: View {
    var icon: String
    var title: String
    var url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

// Component for 2x2 grid layout of collaborators
struct CollaboratorGridItem: View {
    var name: String
    var url: String
    var imageUrl: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(spacing: 8) {
                ProfileImage(url: imageUrl)
                    .frame(width: 50, height: 50)
                
                Text(name)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                    .font(.subheadline)
            }
            .frame(minWidth: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ProfileImage: View {
    var url: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color(UIColor.systemGray4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let imageUrl = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}

// Component for vertical collaborator list - Removed background for cleaner look
struct CollaboratorRow: View {
    var name: String
    var url: String
    var imageUrl: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                ProfileImage(url: imageUrl)
                    .frame(width: 40, height: 40)
                
                Text(name)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
        }
    }
}

// Define these in a separate file if they conflict
struct ConsoleLogsView_Preview: PreviewProvider {
    static var previews: some View {
        ConsoleLogsView()
    }
}
