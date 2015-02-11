// DownloadsViewController.swift
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


enum DownloadsTableViewCellAction: String {
    case Download = "Download"
    case Pause = "Pause"
    case Resume = "Resume"
    case Remove = "Remove"
}


class DownloadsTableViewCellItem {
    
    var identifier: String
    var urlString: String
    var infoLabelTitle: String
    var stateLabelTitle: String
    var progressLabelTitle: String
    var action: DownloadsTableViewCellAction
    var progress: Float
    
    weak var cell: DownloadsTableViewCell?
    
    init(identifier: String, urlString: String, infoLabelTitle: String, stateLabelTitle: String, progressLabelTitle: String, action: DownloadsTableViewCellAction) {
        self.identifier = identifier
        self.urlString = urlString
        self.infoLabelTitle = infoLabelTitle
        self.stateLabelTitle = stateLabelTitle
        self.progressLabelTitle = progressLabelTitle
        self.action = action
        self.progress = 0
    }
    
    func url() -> NSURL {
        return NSURL(string: urlString)!
    }
    
}


class DownloadsViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var identifiers = Array<CheapjackFile.Identifier>()
    var downloadItems = Dictionary<CheapjackFile.Identifier, DownloadsTableViewCellItem>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Cheapjack.delegate = self
    }
    
    @IBAction func addDownloadItem(sender: UIBarButtonItem) {
        let identifier = NSUUID().UUIDString
        let urlString = "https://archive.org/download/testmp3testfile/mpthreetest.mp3"
        let downloadItem = DownloadsTableViewCellItem(identifier: identifier, urlString: urlString, infoLabelTitle: "mp3 test file from archive.org", stateLabelTitle: identifier, progressLabelTitle: "", action: DownloadsTableViewCellAction.Download)
        addDownloadItem(downloadItem, withIdentifier: identifier)
    }
    
    func addDownloadItem(downloadItem: DownloadsTableViewCellItem, withIdentifier identifier: CheapjackFile.Identifier) {
        downloadItems[identifier] = downloadItem
        identifiers.append(identifier)
        
        let indexPathToInsert = NSIndexPath(forRow: downloadItems.count-1, inSection: 0)
        tableView.insertRowsAtIndexPaths(Array<AnyObject>(arrayLiteral: indexPathToInsert), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    func removeDownloadItemWithIdentifier(identifier: CheapjackFile.Identifier) {
        if let index = find(identifiers, identifier) {
            downloadItems.removeValueForKey(identifier)
            identifiers.removeAtIndex(index)
            
            let indexPathToDelete = NSIndexPath(forRow: index, inSection: 0)
            tableView.deleteRowsAtIndexPaths(Array<AnyObject>(arrayLiteral: indexPathToDelete), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
}


extension DownloadsViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return identifiers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DownloadsTableViewCellIdentifier") as DownloadsTableViewCell
        
        cell.delegate = self
        cell.downloadItem = downloadItems[identifiers[indexPath.row]]
        
        return cell
    }
    
}


extension DownloadsViewController: DownloadsTableViewCellDelegate {
    
    func actionButtonPressed(sender: UIButton, inCell cell: DownloadsTableViewCell) {
        switch (sender.titleLabel?.text)! {
        case "Download":
            Cheapjack.download(cell.downloadItem.url(), identifier: cell.downloadItem.identifier)
        case "Pause":
            if Cheapjack.pause(cell.downloadItem.identifier) {
                println("pausing")
            } else {
                println("couldn't pause")
            }
        case "Resume":
            if Cheapjack.resume(cell.downloadItem.identifier) {
                println("resuming")
            } else {
                println("couldn't resume")
            }
        case "Remove":
            if Cheapjack.cancel(cell.downloadItem.identifier) {
                println("cancelled")
            } else {
                println("couldn't cancel")
            }
            removeDownloadItemWithIdentifier(cell.downloadItem.identifier)
        default:
            break
        }
    }
    
}


extension DownloadsViewController: CheapjackDelegate {
    
    func cheapjackManager(manager: CheapjackManager, didChangeState from: CheapjackFile.State, to: CheapjackFile.State, forFile file: CheapjackFile) {
        dispatch_async(dispatch_get_main_queue()) {
            if let index = find(self.identifiers, file.identifier) {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell {
                    switch to {
                    case .Waiting:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Waiting..."
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Pause
                        break
                    case .Downloading:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Downloading..."
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Pause
                        break
                    case .Paused:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Paused"
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Resume
                        break
                    case .Finished:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Finished"
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Remove
                        break
                    case .Cancelled:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Cancelled"
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Download
                        break
                    case .Unknown:
                        self.downloadItems[file.identifier]?.stateLabelTitle = "Unknown"
                        self.downloadItems[file.identifier]?.action = DownloadsTableViewCellAction.Download
                        break
                    }
                    cell.downloadItem = self.downloadItems[file.identifier]
                }
            }
        }
    }
    
    func cheapjackManager(manager: CheapjackManager, didUpdateProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64, forFile file: CheapjackFile) {
        dispatch_async(dispatch_get_main_queue()) {
            if let index = find(self.identifiers, file.identifier) {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? DownloadsTableViewCell {
                    let formattedWrittenBytes = NSByteCountFormatter.stringFromByteCount(totalBytesWritten, countStyle: .File)
                    let formattedTotalBytes = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .File)
                    self.downloadItems[file.identifier]?.progressLabelTitle = "\(Int(progress * 100))% - \(formattedWrittenBytes) of \(formattedTotalBytes)"
                    self.downloadItems[file.identifier]?.progress = progress
                    cell.downloadItem = self.downloadItems[file.identifier]
                }
            }
        }
    }
    
    func cheapjackManager(manager: CheapjackManager, didReceiveError error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) {
            
        }
    }
    
}


extension DownloadsViewController: CheapjackFileDelegate {
    
    func cheapjackFile(file: CheapjackFile, didChangeState from: CheapjackFile.State, to: CheapjackFile.State) {
        dispatch_async(dispatch_get_main_queue()) {
            
        }
    }
    
    func cheapjackFile(file: CheapjackFile, didUpdateProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        dispatch_async(dispatch_get_main_queue()) {
            
        }
    }
    
}

