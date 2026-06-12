import SwiftUI

@main
struct visionOSExamplesApp: App {
    @State private var settings = EndpointSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
    }
}
