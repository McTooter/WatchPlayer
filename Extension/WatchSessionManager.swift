import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {

    static let shared = WatchSessionManager()

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let title = (file.metadata?["title"] as? String) ?? file.fileURL.lastPathComponent
        guard VideoLibrary.store(fileAt: file.fileURL, preferredName: title) else {
            return
        }
        VideoLibrary.shared.reload()
    }
}
