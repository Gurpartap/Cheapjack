// DownloadsTableViewCell.swift
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


protocol DownloadsTableViewCellDelegate: class {
    
    func actionButtonPressed(sender: UIButton, inCell cell: DownloadsTableViewCell)
    
}


class DownloadsTableViewCell: UITableViewCell {
    
    weak var delegate: DownloadsTableViewCellDelegate?
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    var downloadItem: DownloadsTableViewCellItem! {
        didSet {
            resetLabels()
        }
    }
    
    @IBAction func actionButtonPressed(sender: UIButton) {
        delegate?.actionButtonPressed(sender, inCell: self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        downloadItem = DownloadsTableViewCellItem(identifier: "", urlString: "", infoLabelTitle: "", stateLabelTitle: "", progressLabelTitle: "", action: DownloadsTableViewCellAction.Download)
    }
    
    func resetLabels() {
        infoLabel?.text = downloadItem.infoLabelTitle
        stateLabel?.text = downloadItem.stateLabelTitle
        progressLabel?.text = downloadItem.progressLabelTitle
        
        // Both are necessary for changing title without undesired animation.
        actionButton?.titleLabel?.text = downloadItem.action.rawValue
        actionButton?.setTitle(downloadItem.action.rawValue, forState: .Normal)
        
        progressView?.progress = downloadItem.progress
    }
    
}

