import WatchKit
import Foundation

class MovieInterfaceController: WKInterfaceController {

    @IBOutlet weak var moviePlayer: WKInterfaceMovie!

    private var video: VideoItem?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let item = context as? VideoItem {
            video = item
            setTitle(item.title)
        } else {
            setTitle("Video")
        }
    }

    override func willActivate() {
        super.willActivate()
        if let url = video?.url {
            moviePlayer.setMovieURL(url, startAt: 0, loop: false)
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
        moviePlayer.stop()
    }
}
