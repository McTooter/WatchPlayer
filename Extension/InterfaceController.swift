import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!
    @IBOutlet weak var emptyLabel: WKInterfaceLabel!

    private var videos: [VideoItem] = []

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setTitle("My Videos")
        VideoLibrary.shared.onChange = { [weak self] in
            self?.reloadRows()
        }
    }

    override func willActivate() {
        super.willActivate()
        VideoLibrary.shared.reload()
    }

    @IBAction func onRefresh() {
        VideoLibrary.shared.reload()
    }

    private func reloadRows() {
        videos = VideoLibrary.shared.items
        emptyLabel.setHidden(!videos.isEmpty)
        table.setNumberOfRows(videos.count, withRowType: "VideoRow")
        for (index, video) in videos.enumerated() {
            guard let row = table.rowController(at: index) as? VideoRowController else { continue }
            row.configure(video)
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard rowIndex < videos.count else { return }
        pushViewController(withIdentifier: "moviePlayer", context: videos[rowIndex])
    }
}
