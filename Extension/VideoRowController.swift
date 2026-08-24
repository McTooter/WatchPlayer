import WatchKit
import Foundation

class VideoRowController: NSObject {

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var metaLabel: WKInterfaceLabel!

    func configure(_ video: VideoItem) {
        titleLabel.setText(video.title)
        metaLabel.setText(video.detail)
    }
}
