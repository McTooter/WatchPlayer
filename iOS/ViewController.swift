import UIKit
import UniformTypeIdentifiers
import WatchConnectivity

final class ViewController: UIViewController {

    private let statusLabel = UILabel()
    private var pendingTransfers = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Send videos to your Apple Watch"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center

        let pickButton = UIButton(type: .system)
        pickButton.setTitle("Choose Videos", for: .normal)
        pickButton.addTarget(self, action: #selector(pickTapped), for: .touchUpInside)

        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, pickButton, statusLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        updateStatus()
    }

    @objc private func pickTapped() {
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
        guard WCSession.default.activationState == .activated else {
            statusLabel.text = "WatchConnectivity is still activating. Please try again."
            return
        }

        let fm = FileManager.default
        for source in urls {
            let dest = fm.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(source.pathExtension)
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
        try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        DispatchQueue.main.async {
            self.pendingTransfers = max(0, self.pendingTransfers - 1)
            self.updateStatus()
        }
    }
}
