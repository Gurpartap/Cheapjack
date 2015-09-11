// Cheapjack.swift
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

public let Cheapjack = CheapjackManager(backgroundSessionIdentifier: CheapjackConstants.defaultBackgroundSessionIdentifier)

private struct CheapjackConstants {
	static let defaultBackgroundSessionIdentifier = "com.gurpartap.Cheapjack"
	static let downloadsLockQueueIdentifier = "com.gurpartap.Cheapjack.DownloadsLockQueue"
}

public protocol CheapjackManagerDelegate: class {
	func cheapjack(manager: CheapjackManager, failedToMoveFileForDownload: CheapjackDownload, error: NSError)
	func cheapjack(manager: CheapjackManager, completedDownload: CheapjackDownload, error: NSError?)
	func cheapjack(manager: CheapjackManager, receivedChallengeForDownload: CheapjackDownload, challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
	func cheapjack(manager: CheapjackManager, backgroundSessionBecameInvalidWithError: NSError?)
}

public protocol CheapjackDownloadDelegate: class {
	func download(download: CheapjackDownload, stateChanged toState: CheapjackDownloadState, fromState: CheapjackDownloadState)
	func download(download: CheapjackDownload, progressChanged fractionCompleted: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
}

public enum CheapjackDownloadState {
	// // Haven't figured out the state yet
	case Unknown

	case Waiting
	case Downloading
	case Pausing
	case Paused
	case Completed

	// No coming back
	case Cancelled
}

public class CheapjackDownload: NSObject {

	private let manager: CheapjackManager

	public weak var delegate: CheapjackDownloadDelegate?

	private var downloadTask: NSURLSessionDownloadTask?

	public private(set) var lastState: CheapjackDownloadState
	public private(set) var state: CheapjackDownloadState {
		willSet {
			lastState = state
		}
		didSet {
			delegate?.download(self, stateChanged: state, fromState: lastState)
		}
	}

	public private(set) var totalBytesExpectedToWrite: Int64
	public private(set) var totalBytesWritten: Int64 {
		didSet {
			if totalBytesExpectedToWrite > 0 {
				fractionCompleted = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
			} else {
				fractionCompleted = 0
			}

			delegate?.download(self, progressChanged: fractionCompleted, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
		}
	}

	public var url: NSURL
	public var resumeData: NSData?

	public var fractionCompleted: Float = 0

	private init(url: NSURL, manager: CheapjackManager) {
		self.url = url
		self.manager = manager
		self.state = .Unknown
		self.lastState = .Unknown
		self.totalBytesExpectedToWrite = 0
		self.totalBytesWritten = 0
	}

	// MARK:- CheapjackDownload public methods

	public func resume() {
		if let resumeData = resumeData {
			downloadTask?.cancel()
			downloadTask = manager.backgroundSession.downloadTaskWithResumeData(resumeData)
			self.resumeData = nil
		}

		if downloadTask == nil {
			downloadTask = manager.backgroundSession.downloadTaskWithURL(url)
		}

		state = .Waiting
		downloadTask?.resume()
	}

	// Returns resume data
	public func pause(completionHandler: (NSData? -> Void)? = nil) {
		state = .Pausing
		downloadTask?.cancelByProducingResumeData({ (data) -> Void in
			self.state = .Paused
			self.resumeData = data
			completionHandler?(data)
		})
	}

	public func cancel() {
		downloadTask?.cancel()
		state = .Cancelled
	}

	public func remove() {
		cancel()

		dispatch_sync(manager.downloadsLockQueue) {
			if let index = self.manager.downloads.indexOf({ $0 == self }) {
				self.manager.downloads.removeAtIndex(index)
			}
		}
	}

}

public func ==(lhs: CheapjackDownload, rhs: CheapjackDownload) -> Bool {
	return lhs.url.isEqual(rhs.url)
}

public class CheapjackManager: NSObject, NSURLSessionDownloadDelegate, NSURLSessionDelegate {

	//
	public weak var delegate: CheapjackManagerDelegate?

	//
	public var downloads: Array<CheapjackDownload>

	//
	private let downloadsLockQueue: dispatch_queue_t

	//
	public var backgroundSessionCompletionHandler: (() -> Void)?

	//
	public var downloadCompletionHandler: ((CheapjackDownload, NSURLSession, NSURL) -> NSURL?)?

	//
	private let backgroundSessionIdentifier: String

	//
	private lazy var backgroundSession: NSURLSession = self.newBackgroundURLSession()

	public required init(backgroundSessionIdentifier: String) {
		self.downloads = Array<CheapjackDownload>()
		self.downloadsLockQueue = dispatch_queue_create(CheapjackConstants.downloadsLockQueueIdentifier, nil)
		self.backgroundSessionIdentifier = backgroundSessionIdentifier

		super.init()
	}

	private func newBackgroundURLSession() -> NSURLSession {
		let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
		return NSURLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: nil)
	}

	private func handleDownloadTaskWithProgress(downloadTask: NSURLSessionDownloadTask, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		if let download = getDownloadFromTask(downloadTask) {
			if download.state != .Downloading {
				download.state = .Downloading
			}

			download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
			download.totalBytesWritten = totalBytesWritten
		}
	}

	private func getDownloadFromTask(task: NSURLSessionTask) -> CheapjackDownload? {
		var download: CheapjackDownload?

		if let url = task.originalRequest?.URL {
			dispatch_sync(downloadsLockQueue) {
				if let foundAtIndex = self.downloads.indexOf({ $0.url == url }) {
					download = self.downloads[foundAtIndex]
				}
			}
		}

		return download
	}

	// MARK:- Cheapjack public methods

	public func downloadWithURL(url: NSURL, delegate: CheapjackDownloadDelegate?, resumeData: NSData? = nil) -> CheapjackDownload {
		var download = CheapjackDownload(url: url, manager: self)

		dispatch_sync(downloadsLockQueue) {
			if let foundAtIndex = self.downloads.indexOf({ $0 == download }) {
				download = self.downloads[foundAtIndex]
			} else {
				self.downloads.append(download)
			}
		}

		download.delegate = delegate
		download.resumeData = resumeData

		return download
	}

	public func resumeAll() {
		dispatch_sync(downloadsLockQueue) {
			_ = self.downloads.map { $0.resume() }
		}
	}

	public func pauseAll() {
		dispatch_sync(downloadsLockQueue) {
			_ = self.downloads.map { $0.pause() }
		}
	}

	public func cancelAll() {
		dispatch_sync(downloadsLockQueue) {
			_ = self.downloads.map { $0.cancel() }
		}
	}

	public func removeAll() {
		dispatch_sync(downloadsLockQueue) {
			_ = self.downloads.map { $0.cancel() }
			self.downloads.removeAll()
		}
	}

	// MARK:- NSURLSessionDownloadDelegate

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		if let download = getDownloadFromTask(downloadTask) {
			download.state = .Completed
			if let moveTo = downloadCompletionHandler?(download, session, location) {
				do {
					try NSFileManager.defaultManager().moveItemAtURL(location, toURL: moveTo)
				} catch let error as NSError {
					self.delegate?.cheapjack(self, failedToMoveFileForDownload: download, error: error)
				}
			}
		}
	}

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: fileOffset, totalBytesExpectedToWrite: expectedTotalBytes)
	}

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
	}

	// MARK:- NSURLSessionTaskDelegate

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
		if let download = getDownloadFromTask(task) {
			delegate?.cheapjack(self, receivedChallengeForDownload: download, challenge: challenge, completionHandler: completionHandler)
		}
	}

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let download = getDownloadFromTask(task) {
			delegate?.cheapjack(self, completedDownload: download, error: error)
		}
	}

	// MARK:- NSURLSessionDelegate

	public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
		delegate?.cheapjack(self, backgroundSessionBecameInvalidWithError: error)
	}

	public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
		// If there are no tasks remaining, then the session is complete.
		session.getTasksWithCompletionHandler { (_, _, downloadTasks) -> Void in
			if downloadTasks.count == 0 {
				dispatch_async(dispatch_get_main_queue()) {
					self.backgroundSessionCompletionHandler?()
					self.backgroundSessionCompletionHandler = nil
				}
			}
		}
	}

}
