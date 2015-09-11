# Cheapjack

[![Carthage compatible][carthage-image]][carthage-url]
[![License][license-image]][license-url]

A drop-in framework for adding a background download manager to your iOS app.

<img src="http://i.imgur.com/B7dGvUe.png" height="773" width="435">

`CheapjackExample` project, as pictured above, demonstrates downloading multiple files and displaying their states in a custom `UITableViewCell`.

For advanced usage and control over downloads refer to definitions in [Cheapjack.swift](https://github.com/Gurpartap/Cheapjack/blob/master/Cheapjack/Cheapjack.swift).

#### Usage

Cheapjack's pretty simple to use.

```swift
class MyDownloadManager {
	class func prepareForDownload() {
		Cheapjack.downloadCompletionHandler = { (download, session, location) -> NSURL? in
			// Return NSURL of location to move the file to once the download completes.
			// Or do it manually and return nil.
			return nil
		}
	}

	func downloadFile() {
		MyDownloadManager.prepareForDownload()

		let url = NSURL("https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip") // 2.2 MB
		Cheapjack.downloadWithURL(url, delegate: self)
	}
}
```

In your app delegate implementation:

```swift
func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
	MyDownloadManager.prepareForDownload()
	Cheapjack.backgroundSessionCompletionHandler = completionHandler
}
```

For download states and progress reporting, see [Cheapjack.swift](https://github.com/Gurpartap/Cheapjack/blob/master/Cheapjack/Cheapjack.swift) public methods and the full featured implementation in the included example project.

#### Requirements

* iOS 8.1 SDK+
* Xcode 7+

#### Install with [Carthage](https://github.com/Carthage/Carthage)

Add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "Gurpartap/Cheapjack"
```

Run `carthage update --platform iOS` and follow the [adding framework instructions in Carthage's README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

#### Manual Installation

```sh
git clone https://github.com/Gurpartap/Cheapjack.git
cd Cheapjack
```

1. Add Cheapjack.xcodeproj to your Xcode project or workspace.
2. Add Cheapjack.framework to Linked Frameworks and Libraries in your app's target.
3. Create a *New Copy Files Phase* with *Frameworks* as the *Destination* in the target's Build Phases.
4. Add Cheapjack.framework to this Copy Files build phase.
5. Try `import Cheapjack` in your code. Build should succeeed.

#### Contact

* [http://twitter.com/Gurpartap](http://twitter.com/Gurpartap)

[carthage-url]: https://github.com/Carthage/Carthage
[carthage-image]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat

[license-url]: https://raw.githubusercontent.com/Gurpartap/Cheapjack/master/LICENSE
[license-image]: https://img.shields.io/badge/license-MIT-brightgreen.svg
