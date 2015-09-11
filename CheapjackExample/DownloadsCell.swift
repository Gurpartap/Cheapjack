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

class DownloadsCell: UITableViewCell {

	@IBOutlet var infoLabel: UILabel!
	@IBOutlet var stateLabel: UILabel!
	@IBOutlet var progressLabel: UILabel!
	@IBOutlet var actionButton: UIButton!
	@IBOutlet var progressView: UIProgressView!

    override func awakeFromNib() {
		super.awakeFromNib()
		reset()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		reset()
	}

	func reset() {
		infoLabel?.text = ""
		stateLabel?.text = ""
		progressLabel?.text = ""

		// Both are necessary for changing title without undesired animation.
		actionButton?.titleLabel?.text = DownloadsCellAction.Download.rawValue
		actionButton?.setTitle(DownloadsCellAction.Download.rawValue, forState: .Normal)

		progressView?.progress = 0
    }

}
