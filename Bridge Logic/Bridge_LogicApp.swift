import SwiftUI
import Foundation

@main
struct Bridge_LogicApp: App {
    @StateObject private var driftStore = DataStore()
    @State private var driftGateReady: Bool? = nil

    private let driftSourceLink = "https://example.com"
    private let driftCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = driftGateReady {
                    if ready {
                        BridgeWaterPanel(urlString: driftSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(driftStore)
                            .preferredColorScheme(.light)
                    }
                } else {
                    BridgeLaunchScreen()
                        .preferredColorScheme(.light)
                        .onAppear { beginDriftGateCheck() }
                }
            }
        }
    }

    private func beginDriftGateCheck() {
        guard let url = URL(string: driftSourceLink) else {
            driftGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = DriftRedirectBeacon(checkDomain: driftCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    driftGateReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.driftCheckDomain) {
                    driftGateReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(self.driftCheckDomain) {
                    driftGateReady = false
                    return
                }
                if error != nil {
                    driftGateReady = false
                    return
                }
                driftGateReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if driftGateReady == nil {
                driftGateReady = false
            }
        }
    }
}

final class DriftRedirectBeacon: NSObject, URLSessionTaskDelegate {
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
