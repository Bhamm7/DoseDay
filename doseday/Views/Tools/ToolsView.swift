import SwiftUI

struct ToolsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    LabResultsEditorView(date: Date())
                } label: {
                    toolRow(icon: "flask", title: "Labs Entry")
                }

                NavigationLink {
                    Text("Coming soon")
                        .foregroundStyle(DDTheme.textTertiary)
                        .navigationTitle("Reconstitution Calculator")
                } label: {
                    toolRow(icon: "function", title: "Reconstitution Calculator")
                }

                NavigationLink {
                    Text("Coming soon")
                        .foregroundStyle(DDTheme.textTertiary)
                        .navigationTitle("Insights")
                } label: {
                    toolRow(icon: "lightbulb", title: "Insights")
                }

                NavigationLink {
                    Text("Coming soon")
                        .foregroundStyle(DDTheme.textTertiary)
                        .navigationTitle("Export Data")
                } label: {
                    toolRow(icon: "square.and.arrow.up", title: "Export Data")
                }
            } header: {
                Text("Tools")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.textTertiary)
            }

            Section {
                NavigationLink {
                    SymptomTagManagerView()
                } label: {
                    toolRow(icon: "heart.text.clipboard", title: "Symptoms Management")
                }
            } header: {
                Text("Manage")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.textTertiary)
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    toolRow(icon: "gearshape", title: "App Settings")
                }
            } header: {
                Text("Settings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.textTertiary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DDTheme.canvas)
        .navigationTitle("Tools")
    }

    private func toolRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(DDTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: DDTheme.radiusMedium))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(DDTheme.textPrimary)
        }
    }
}
