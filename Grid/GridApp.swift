import SwiftUI

@main
struct GridApp: App {

	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		Settings {
			ContentView()
		}
	}
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!").padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
