## Cheapjack

A drop-in framework for adding a background download manager to your iOS app.

<img src ="http://i.imgur.com/HjriN1X.png">

`Cheapjack-Example` project, as pictured above, demonstrates downloading multiple files and displaying their states in a custom `UITableViewCell`.

For advanced usage and control over downloads, with multiple listeners and delegates, refer to definitions in `Cheapjack.swift`.

Cheapjack is a work in progress. Any useful contributions will be lovingly accepted and attributed!

##### Basic Usage

A single page example view controller would look something like:

```Swift
import Cheapjack

class ViewController: UIViewController {

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var actionButton: UIButton! // Download, Pause, Resume, etc.

    var downloads = Array<CheapjackFile.Identifier>() // typealias CheapjackFile.Identifier = String

    @IBAction actionButtonPressed(sender: UIButton) {
        let identifier = NSUUID().UUIDString
        downloads.append(identifier) // For later reference. If you want to.
        let url = NSURL(string: "https://archive.org/download/testmp3testfile/mpthreetest.mp3")!
        
        Cheapjack.download(url, identifier: identifier, delegate: self, didChangeStateBlock: { (from, to) in
            var currentStatus: String!
            var nextAction: String!
            
            switch to {
            case .Waiting:
                currentStatus = "Waiting...";     nextAction = "Pause"
            case .Downloading:
                currentStatus = "Downloading..."; nextAction = "Pause"
            case .Paused:
                currentStatus = "Paused";         nextAction = "Resume"
            case .Finished:
                currentStatus = "Finished";       nextAction = "Remove"
            case .Cancelled:
                currentStatus = "Cancelled";      nextAction = "Download"
            case .Unknown:
                currentStatus = "Unknown";        nextAction = "Download"
            }

            dispatch_async(dispatch_get_main_queue()) {
                // Update the UI.
                self.statusLabel.text = currentStatus
                self.actionButton?.setTitle(nextAction, forState: .Normal)
            }
        }, didUpdateProgressBlock: { (progress, totalBytesWritten, totalBytesExpectedToWrite) in
            let formattedWrittenBytes = NSByteCountFormatter.stringFromByteCount(totalBytesWritten, countStyle: .File)
            let formattedTotalBytes = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .File)
            dispatch_async(dispatch_get_main_queue()) {
                self.progressLabel.text = "\(Int(progress * 100))% - \(formattedWrittenBytes) of \(formattedTotalBytes)"
                self.progressView.progress = progress
            }
        })
    }
}
```

##### Requirements

* iOS 8.1 SDK+
* Xcode 6.1+

##### Manual Installation

```sh
git clone https://github.com/Gurpartap/Cheapjack.git
cd Cheapjack
```

1. Add Cheapjack.xcodeproj to your Xcode project or workspace.
2. Add Cheapjack.framework to Linked Frameworks and Libraries in your app's target.
3. Create a *New Copy Files Phase* with *Frameworks* as the *Destination* in the target's Build Phases.
4. Add Cheapjack.framework to this Copy Files build phase.
5. Try `import Cheapjack` in your code. Build should succeeed.

##### Creator

* [Gurpartap Singh](http://gurpartap.com/) ([@Gurpartap](http://twitter.com/Gurpartap))

##### License

Cheapjack is licensed under MIT license. See LICENSE for details.

