// DownloadsViewModel.swift
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

import Foundation
import Cheapjack
import ReactiveCocoa

class DownloadsViewModel: CheapjackManagerDelegate {

	let downloads = MutableProperty<Array<Download>>(Array<Download>())

	func addDownload(download: Download) {
		download.listenForChanges()
		downloads.value.append(download)
	}

	func cheapjack(manager: CheapjackManager, backgroundSessionBecameInvalidWithError: NSError?) {

	}

	func cheapjack(manager: CheapjackManager, completedDownload: CheapjackDownload, error: NSError?) {

	}

	func cheapjack(manager: CheapjackManager, failedToMoveFileForDownload: CheapjackDownload, error: NSError) {

	}

	func cheapjack(manager: CheapjackManager, receivedChallengeForDownload: CheapjackDownload, challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

	}
}
