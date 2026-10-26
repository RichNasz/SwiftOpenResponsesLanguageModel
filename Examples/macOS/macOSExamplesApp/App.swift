import SwiftUI

@main
struct macOSExamplesApp: App {
    @State private var settings = EndpointSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .defaultSize(width: 980, height: 720)
    }
}
