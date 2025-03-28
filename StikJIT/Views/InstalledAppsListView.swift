//
//  InstalledAppsListView.swift
//  StikJIT
//
//  Created by Stossy11 on 28/03/2025.
//

import SwiftUI

struct InstalledAppsListView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @State private var selectedBackgroundColor: Color = Color(hex: UserDefaults.standard.string(forKey: "customBackgroundColor") ?? "#000000") ?? Color.primaryBackground
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject var viewModel = InstalledAppsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    var onSelect: (String) -> Void
    
    var filteredApps: [String] {
        if searchText.isEmpty {
            return Array(viewModel.apps.keys) // Use the keys (app names)
        } else {
            return viewModel.apps.filter { $0.value.localizedCaseInsensitiveContains(searchText) }.map { $0.key }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                selectedBackgroundColor.edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(filteredApps, id: \.self) { bundleId in
                        Button(action: {
                            onSelect(bundleId) // Select using the app's bundle ID
                        }) {
                            Text(viewModel.apps[bundleId] ?? "Unknown App")
                                .font(.system(.body, design: .rounded))
                                .padding(.vertical, 8)
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Installed Apps")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search Apps")
            }
            .onReceive(timer) { _ in
                refreshBackground()
            }
            .onAppear {
                print(filteredApps)
            }
        }
    }

    private func refreshBackground() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }
}
