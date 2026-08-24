import UIKit
import UniformTypeIdentifiers
import WatchConnectivity

final class ViewController: UIViewController {

    @IBOutlet private weak var statusLabel: UILabel!

    private var pendingTransfers = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WatchPlayer"
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        updateStatus()
    }

    @IBAction private func pickTapped(_ sender: Any) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    private func updateStatus() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            statusLabel.text = "WatchConnectivity activating..."
            return
        }
        let session = WCSession.default
        let reachability = session.isReachable ? "Watch reachable" : "Watch paired (offline)"
        if pendingTransfers == 0 {
            statusLabel.text = "\(reachability) · nothing queued"
        } else {
            statusLabel.text = "\(reachability) · \(pendingTransfers) queued"
        }
    }
}

extension ViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard WCSession.isSupported() else { return }
        let fm = FileManager.default
        for source in urls {
            let dest = fm.temporaryDirectory.appendingPathComponent(source.lastPathComponent)
            try? fm.removeItem(at: dest)
            do {
                try fm.copyItem(at: source, to: dest)
            } catch {
                continue
            }
            WCSession.default.transferFile(dest, metadata: ["title": source.lastPathComponent])
            pendingTransfers += 1
        }
        updateStatus()
    }
}

extension ViewController: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async { self.updateStatus() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession,
                 didFinish fileTransfer: WCSessionFileTransfer,
                 error: Error?) {
        DispatchQueue.main.async {
            self.pendingTransfers = max(0, self.pendingTransfers - 1)
            self.updateStatus()
        }
    }
}
