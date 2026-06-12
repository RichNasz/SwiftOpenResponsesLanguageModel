import SwiftUI

struct SettingsSheet: View {
    @Environment(EndpointSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Endpoint") {
                    TextField("Base URL", text: $settings.baseURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Model ID", text: $settings.modelID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("API Key (optional)", text: $settings.apiKey)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
