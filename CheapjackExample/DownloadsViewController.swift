// ViewController.swift
//
// Copyright (c) 2015 Gurpartap Singh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Cheapjack
import ReactiveCocoa

enum DownloadsCellAction: String {
	case Download = "Download"
	case Pause = "Pause"
	case Resume = "Resume"
	case Remove = "Remove"
	case None = "..."
}

class DownloadsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet var tableView: UITableView!

	private lazy var viewModel = DownloadsViewModel()

	let downloadLinks = [
		"sample_iPod.m4v (2.2 MB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip",
		"sample_iTunes.mov (3 MB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iTunes.mov.zip",
		"sample_mpeg4.mp4 (236 KB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_mpeg4.mp4.zip",
		"sample_3GPP.3gp (28 KB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_3GPP.3gp.zip",
		"sample_3GPP2.3g2 (27 KB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_3GPP2.3g2.zip",
		"sample_mpeg2.m2v (1.1 MB)": "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_mpeg2.m2v.zip"
	]

	override func viewDidLoad() {
		super.viewDidLoad()

		Cheapjack.delegate = viewModel
		Cheapjack.downloadCompletionHandler = { (download, session, location) -> NSURL? in
			// Return NSURL of location to move the downloaded file to.
			// Or do it manually and return nil.
			return nil
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	@IBAction func addButtonPressed() {
		Cheapjack.removeAll()
		viewModel.downloads.value = Array<Download>()

		for (title, urlString) in downloadLinks {
			let url = NSURL(string: urlString)!
			let download = Download(title: title, url: url)
			viewModel.addDownload(download)
		}

		tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
	}

	// MARK:- UITableViewDataSource

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.downloads.value.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("DownloadsCell", forIndexPath: indexPath) as! DownloadsCell
		let download = viewModel.downloads.value[indexPath.row]
		let cellViewModel = download.viewModel
		let reuseSignal = prepareForReuseSignal(cell)

		DynamicProperty(object: cell.infoLabel, keyPath: "text") <~ cellViewModel.info.producer.takeUntil(reuseSignal).observeOn(UIScheduler()).map({ $0 })
		DynamicProperty(object: cell.stateLabel, keyPath: "text") <~ cellViewModel.state.producer.takeUntil(reuseSignal).observeOn(UIScheduler()).map({ $0 })
		DynamicProperty(object: cell.progressView, keyPath: "progress") <~ cellViewModel.progress.producer.takeUntil(reuseSignal).observeOn(UIScheduler()).map({ $0 })
		DynamicProperty(object: cell.progressLabel, keyPath: "text") <~ cellViewModel.progressLabelText.producer.takeUntil(reuseSignal).observeOn(UIScheduler()).map({ $0 })

		cellViewModel.nextAction.producer
			.takeUntil(reuseSignal)
			.observeOn(UIScheduler())
			.start(next: { [weak cell] nextAction in
				cell?.actionButton.titleLabel?.text = nextAction.rawValue
				cell?.actionButton.setTitle(nextAction.rawValue, forState: .Normal)
			})

		controlEventsSignal(cell.actionButton, controlEvents: .TouchUpInside)
			.takeUntil(reuseSignal)
			.start(next: { [weak download, weak cell] sender -> Void in
				if let actionText = cell?.actionButton.titleLabel?.text {
					if let action = DownloadsCellAction(rawValue: actionText) {
						switch action {
						case .Download, .Resume:
							download?.cheapjackDownload.resume()
						case .None:
							break
						case .Pause:
							download?.cheapjackDownload.pause({ (resumeData) -> Void in
								print("Got resume data")
							})
						case .Remove:
							download?.cheapjackDownload.remove()
							self.viewModel.downloads.value.removeAtIndex(indexPath.row)
							tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
						}
					}
				}
			})

		return cell
	}

}
