import SwiftUI
import Combine

class ImageLoader: NSObject, ObservableObject, URLSessionDelegate {
    @Published var image: NSImage?
    private var cancellable: AnyCancellable?
    
    // Custom session to handle invalid SSL certificates
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    func load(url: URL) {
        cancellable = session.dataTaskPublisher(for: url)
            .map { NSImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
    
    // Delegate method to ignore SSL errors
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

struct AsyncImageView: View {
    @StateObject private var loader = ImageLoader()
    let url: URL
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
            } else {
                Image(systemName: "tv")
                    .resizable()
                    .foregroundStyle(.gray)
            }
        }
        .onAppear {
            loader.load(url: url)
        }
    }
}
