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
	func cheapjack(_ manager: CheapjackManager, failedToMoveFileForDownload: CheapjackDownload, error: Error)
	func cheapjack(_ manager: CheapjackManager, completedDownload: CheapjackDownload, error: Error?)
	func cheapjack(_ manager: CheapjackManager, receivedChallengeForDownload: CheapjackDownload, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	func cheapjack(_ manager: CheapjackManager, backgroundSessionBecameInvalidWithError: Error?)
}

public protocol CheapjackDownloadDelegate: class {
	func download(_ download: CheapjackDownload, stateChanged toState: CheapjackDownloadState, fromState: CheapjackDownloadState)
	func download(_ download: CheapjackDownload, progressChanged fractionCompleted: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
}

public enum CheapjackDownloadState {
	// // Haven't figured out the state yet
	case unknown

	case waiting
	case downloading
	case pausing
	case paused
	case completed

	// No coming back
	case cancelled
}

open class CheapjackDownload: NSObject {

	fileprivate let manager: CheapjackManager

	open weak var delegate: CheapjackDownloadDelegate?

	fileprivate var downloadTask: URLSessionDownloadTask?

	open fileprivate(set) var lastState: CheapjackDownloadState
	open fileprivate(set) var state: CheapjackDownloadState {
		willSet {
			lastState = state
		}
		didSet {
			delegate?.download(self, stateChanged: state, fromState: lastState)
		}
	}

	open fileprivate(set) var totalBytesExpectedToWrite: Int64
	open fileprivate(set) var totalBytesWritten: Int64 {
		didSet {
			if totalBytesExpectedToWrite > 0 {
				fractionCompleted = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
			} else {
				fractionCompleted = 0
			}

			delegate?.download(self, progressChanged: fractionCompleted, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
		}
	}

	open var url: URL
	open var resumeData: Data?

	open var fractionCompleted: Float = 0

	fileprivate init(url: URL, manager: CheapjackManager) {
		self.url = url
		self.manager = manager
		self.state = .unknown
		self.lastState = .unknown
		self.totalBytesExpectedToWrite = 0
		self.totalBytesWritten = 0
	}

	// MARK:- CheapjackDownload public methods

	open func resume() {
		if let resumeData = resumeData {
			downloadTask?.cancel()
			downloadTask = manager.backgroundSession.downloadTask(withResumeData: resumeData)
			self.resumeData = nil
		}

		if downloadTask == nil {
			downloadTask = manager.backgroundSession.downloadTask(with: url)
		}

		state = .waiting
		downloadTask?.resume()
	}

	// Returns resume data
	open func pause(_ completionHandler: ((Data?) -> Void)? = nil) {
		state = .pausing
		downloadTask?.cancel(byProducingResumeData: { (data) -> Void in
			self.state = .paused
			self.resumeData = data
			completionHandler?(data)
		})
	}

	open func cancel() {
		downloadTask?.cancel()
		state = .cancelled
	}

	open func remove() {
		cancel()

		manager.downloadsLockQueue.sync {
			if let index = self.manager.downloads.index(where: { $0 == self }) {
				self.manager.downloads.remove(at: index)
			}
		}
	}

}

public func ==(lhs: CheapjackDownload, rhs: CheapjackDownload) -> Bool {
	return (lhs.url == rhs.url)
}

open class CheapjackManager: NSObject, URLSessionDownloadDelegate, URLSessionDelegate {

	//
	open weak var delegate: CheapjackManagerDelegate?

	//
	open var downloads: Array<CheapjackDownload>

	//
	fileprivate let downloadsLockQueue: DispatchQueue

	//
	open var backgroundSessionCompletionHandler: (() -> Void)?

	//
	open var downloadCompletionHandler: ((CheapjackDownload, Foundation.URLSession, URL) -> URL?)?

	//
	fileprivate let backgroundSessionIdentifier: String

	//
	fileprivate lazy var backgroundSession: Foundation.URLSession = self.newBackgroundURLSession()

	public required init(backgroundSessionIdentifier: String) {
		self.downloads = Array<CheapjackDownload>()
		self.downloadsLockQueue = DispatchQueue(label: CheapjackConstants.downloadsLockQueueIdentifier, attributes: [])
		self.backgroundSessionIdentifier = backgroundSessionIdentifier

		super.init()
	}

	fileprivate func newBackgroundURLSession() -> Foundation.URLSession {
		let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
		return Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: nil)
	}

	fileprivate func handleDownloadTaskWithProgress(_ downloadTask: URLSessionDownloadTask, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		if let download = getDownloadFromTask(downloadTask) {
			if download.state != .downloading {
				download.state = .downloading
			}

			download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
			download.totalBytesWritten = totalBytesWritten
		}
	}

	fileprivate func getDownloadFromTask(_ task: URLSessionTask) -> CheapjackDownload? {
		var download: CheapjackDownload?

		if let url = task.originalRequest?.url {
			downloadsLockQueue.sync {
				if let foundAtIndex = self.downloads.index(where: { $0.url == url }) {
					download = self.downloads[foundAtIndex]
				}
			}
		}

		return download
	}

	// MARK:- Cheapjack public methods

	open func downloadWithURL(_ url: URL, delegate: CheapjackDownloadDelegate?, resumeData: Data? = nil) -> CheapjackDownload {
		var download = CheapjackDownload(url: url, manager: self)

		downloadsLockQueue.sync {
			if let foundAtIndex = self.downloads.index(where: { $0 == download }) {
				download = self.downloads[foundAtIndex]
			} else {
				self.downloads.append(download)
			}
		}

		download.delegate = delegate
		download.resumeData = resumeData

		return download
	}

	open func resumeAll() {
		downloadsLockQueue.sync {
			_ = self.downloads.map { $0.resume() }
		}
	}

	open func pauseAll() {
		downloadsLockQueue.sync {
			_ = self.downloads.map { $0.pause() }
		}
	}

	open func cancelAll() {
		downloadsLockQueue.sync {
			_ = self.downloads.map { $0.cancel() }
		}
	}

	open func removeAll() {
		downloadsLockQueue.sync {
			_ = self.downloads.map { $0.cancel() }
			self.downloads.removeAll()
		}
	}

	// MARK:- NSURLSessionDownloadDelegate

	open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		if let download = getDownloadFromTask(downloadTask) {
			download.state = .completed
			if let moveTo = downloadCompletionHandler?(download, session, location) {
				do {
					try FileManager.default.moveItem(at: location, to: moveTo)
				} catch let error as NSError {
					self.delegate?.cheapjack(self, failedToMoveFileForDownload: download, error: error)
				}
			}
		}
	}

	open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: fileOffset, totalBytesExpectedToWrite: expectedTotalBytes)
	}

	open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
	}

	// MARK:- NSURLSessionTaskDelegate

	open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if let download = getDownloadFromTask(task) {
			delegate?.cheapjack(self, receivedChallengeForDownload: download, challenge: challenge, completionHandler: completionHandler)
		}
	}

	open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let download = getDownloadFromTask(task) {
			delegate?.cheapjack(self, completedDownload: download, error: error )
		}
	}

	// MARK:- NSURLSessionDelegate

	open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		delegate?.cheapjack(self, backgroundSessionBecameInvalidWithError: error )
	}

	open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		// If there are no tasks remaining, then the session is complete.
		session.getTasksWithCompletionHandler { (_, _, downloadTasks) -> Void in
			if downloadTasks.count == 0 {
				DispatchQueue.main.async {
					self.backgroundSessionCompletionHandler?()
					self.backgroundSessionCompletionHandler = nil
				}
			}
		}
	}

}
