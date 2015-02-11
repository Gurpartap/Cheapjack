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


public let Cheapjack = CheapjackManager.defaultManager


struct SessionProperties {
    static let backgroundSessionIdentifier = "com.gurpartap.Cheapjack"
}


public protocol CheapjackDelegate: class {
    func cheapjackManager(manager: CheapjackManager, didChangeState from: CheapjackFile.State, to: CheapjackFile.State, forFile file: CheapjackFile)
    func cheapjackManager(manager: CheapjackManager, didUpdateProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64, forFile file: CheapjackFile)
    func cheapjackManager(manager: CheapjackManager, didReceiveError error: NSError?)
}


public protocol CheapjackFileDelegate: class {
    func cheapjackFile(file: CheapjackFile, didChangeState from: CheapjackFile.State, to: CheapjackFile.State)
    func cheapjackFile(file: CheapjackFile, didUpdateProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
}


public func ==(lhs: CheapjackFile, rhs: CheapjackFile) -> Bool {
    return lhs.identifier == rhs.identifier
}


public class CheapjackFile: Equatable {
    
    // A listener may implement either of delegate and blocks.
    public class Listener {
        
        public typealias DidChangeStateBlock = (from: CheapjackFile.State, to: CheapjackFile.State) -> (Void)
        public typealias DidUpdateProgressBlock = (progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> (Void)
        
        
        public weak var delegate: CheapjackFileDelegate?
        public var didChangeStateBlock: CheapjackFile.Listener.DidChangeStateBlock?
        public var didUpdateProgressBlock: CheapjackFile.Listener.DidUpdateProgressBlock?
        
        public init(delegate: CheapjackFileDelegate? = nil, didChangeStateBlock: CheapjackFile.Listener.DidChangeStateBlock? = nil, didUpdateProgressBlock: CheapjackFile.Listener.DidUpdateProgressBlock? = nil) {
            self.delegate = delegate
            self.didChangeStateBlock = didChangeStateBlock
            self.didUpdateProgressBlock = didUpdateProgressBlock
        }
        
    }
    
    
    // File states default to .Unknown
    public enum State {
        case Unknown
        case Waiting
        case Downloading
        case Paused
        case Finished
        case Cancelled
    }
    
    
    public typealias Identifier = String
    
    
    // MARK: - CheapjackFile public properties
    
    private weak var manager: CheapjackManager?
    public var identifier: CheapjackFile.Identifier
    public var url: NSURL
    public var progress: Float {
        if totalBytesExpectedToWrite > 0 {
            return Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        } else {
            return 0
        }
    }
    
    // MARK: - CheapjackFile public read-only properties
    
    public private(set) var lastState: CheapjackFile.State
    public private(set) var state: CheapjackFile.State {
        willSet {
            lastState = state
        }
        didSet {
            notifyChangeStateListeners()
        }
    }
    public private(set) var totalBytesExpectedToWrite: Int64
    public private(set) var totalBytesWritten: Int64 {
        didSet {
            notifyUpdateProgressListeners()
        }
    }
    
    // MARK: - CheapjackFile private properties
    
    private var listeners: Array<CheapjackFile.Listener>
    private var downloadTask: NSURLSessionDownloadTask?
    
    public init(identifier: CheapjackFile.Identifier, url: NSURL, listeners: Array<CheapjackFile.Listener>? = nil) {
        self.identifier = identifier
        self.url = url
        self.state = .Unknown
        self.lastState = .Unknown
        self.totalBytesWritten = 0
        self.totalBytesExpectedToWrite = 0
        self.listeners = listeners ?? Array<CheapjackFile.Listener>()
    }
    
    // MARK: - CheapjackFile private setter methods
    
    private func addListener(listener: CheapjackFile.Listener) {
        listeners.append(listener)
    }
    
    private func setState(to: CheapjackFile.State) {
        state = to
    }
    
    private func setTotalBytesWritten(bytes: Int64) {
        totalBytesWritten = bytes
    }
    
    private func setTotalBytesExpectedToWrite(bytes: Int64) {
        totalBytesExpectedToWrite = bytes
    }
    
    // MARK: - CheapjackFile private notify methods
    
    private func notifyChangeStateListeners() {
        if let manager = manager {
            // CheapjackDelegate
            manager.delegate?.cheapjackManager(manager, didChangeState: lastState, to: state, forFile: self)
        }
        
        // CheapjackFile.Listener
        for listener in listeners {
            // CheapjackFileDelegate
            listener.delegate?.cheapjackFile(self, didChangeState: lastState, to: state)
            
            // CheapjackFile.Listener.DidChangeStateBlock
            if let didChangeStateBlock = listener.didChangeStateBlock {
                didChangeStateBlock(from: lastState, to: state)
            }
        }
    }
    
    private func notifyUpdateProgressListeners() {
        if let manager = manager {
            // CheapjackDelegate
            manager.delegate?.cheapjackManager(manager, didUpdateProgress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite, forFile: self)
        }
        
        // CheapjackFile.Listener
        for listener in listeners {
            // CheapjackFileDelegate
            listener.delegate?.cheapjackFile(self, didUpdateProgress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            
            // CheapjackFile.Listener.DidUpdateProgressBlock
            if let didUpdateProgressBlock = listener.didUpdateProgressBlock {
                didUpdateProgressBlock(progress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
        }
    }
    
}


public class CheapjackManager: NSObject {
    
    public weak var delegate: CheapjackDelegate?
    
    var files: Dictionary<CheapjackFile.Identifier, CheapjackFile>
    // var session: NSURLSession!
    var backgroundSession: NSURLSession!
    
    class var defaultManager: CheapjackManager {
        struct Singleton {
            static let manager = CheapjackManager()
        }
        
        return Singleton.manager
    }
    
    override init() {
        files = Dictionary<CheapjackFile.Identifier, CheapjackFile>()
        
        super.init()
        
        // let defaultSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        // session = NSURLSession(configuration: defaultSessionConfiguration, delegate: self, delegateQueue: nil)
        
        let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(SessionProperties.backgroundSessionIdentifier)
        backgroundSession = NSURLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: nil)
    }
    
    // Helper method for starting a download for a new CheapjackFile instance.
    public func download(url: NSURL, identifier: CheapjackFile.Identifier, delegate: CheapjackFileDelegate? = nil, didChangeStateBlock: CheapjackFile.Listener.DidChangeStateBlock? = nil, didUpdateProgressBlock: CheapjackFile.Listener.DidUpdateProgressBlock? = nil) {
        let listener = CheapjackFile.Listener(delegate: delegate, didChangeStateBlock: didChangeStateBlock, didUpdateProgressBlock: didUpdateProgressBlock)
        let file = CheapjackFile(identifier: identifier, url: url, listeners: Array<CheapjackFile.Listener>(arrayLiteral: listener))
        resume(file)
    }
    
    public func pendingDownloads() -> Int {
        return filter(self.files, { (identifier, file) in
            return file.state != .Finished && file.state != .Cancelled
        }).count
    }
    
}


// MARK: - Action on file with identifier

extension CheapjackManager {
    
    public func resume(identifier: CheapjackFile.Identifier) -> Bool {
        if let file = files[identifier] {
            resume(file)
            return true
        }
        return false
    }
    
    public func pause(identifier: CheapjackFile.Identifier) -> Bool {
        if let file = files[identifier] {
            pause(file)
            return true
        }
        return false
    }
    
    public func cancel(identifier: CheapjackFile.Identifier) -> Bool {
        if let file = files[identifier] {
            cancel(file)
            return true
        }
        return false
    }
    
}


// MARK: - Action on CheapjackFile

extension CheapjackManager {
    
    public func resume(file: CheapjackFile) {
        file.manager = self
        files[file.identifier] = file
        
        file.setState(.Waiting)
        file.downloadTask = backgroundSession.downloadTaskWithURL(file.url)
        file.downloadTask?.taskDescription = file.identifier
        file.downloadTask?.resume()
    }
    
    public func pause(file: CheapjackFile) {
        file.downloadTask?.cancelByProducingResumeData({ resumeDataOrNil in
            if let data = resumeDataOrNil {
                file.setState(.Paused)
                println("paused")
            } else {
                file.setState(.Cancelled)
                // TODO: Handle server not supporting resumes.
                println("can't resume this later. cancelling instead.")
            }
        })
    }
    
    public func cancel(file: CheapjackFile) {
        file.setState(.Cancelled)
        file.downloadTask?.cancel()
    }
    
}


// MARK: - Action on all

extension CheapjackManager {
    
    public func resumeAll() {
        for file in files.values {
            resume(file)
        }
    }
    
    public func pauseAll() {
        for file in files.values {
            pause(file)
        }
    }
    
    public func cancelAll() {
        for file in files.values {
            cancel(file)
        }
    }
    
}


extension CheapjackManager {
    public func remove(identifier: CheapjackFile.Identifier) {
        files.removeValueForKey(identifier)
    }
    
    public func remove(filesWithState: CheapjackFile.State) {
        var filesCopy = files
        for (identifier, file) in filesCopy {
            if file.state != filesWithState {
                filesCopy.removeValueForKey(identifier)
            }
        }
        files = filesCopy
    }
}


extension CheapjackManager: NSURLSessionDownloadDelegate {
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let file = files[downloadTask.taskDescription] {
            file.setState(.Finished)
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let file = files[downloadTask.taskDescription] {
            if file.state != CheapjackFile.State.Downloading {
                file.setState(.Downloading)
            }
            
            file.setTotalBytesWritten(totalBytesWritten)
            file.setTotalBytesExpectedToWrite(totalBytesExpectedToWrite)
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        println("didResumeAtOffset")
    }
    
}


extension CheapjackManager: NSURLSessionDelegate {
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            println(error)
            delegate?.cheapjackManager(self, didReceiveError: error)
        }
    }
    
    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if let error = error {
            println(error)
            delegate?.cheapjackManager(self, didReceiveError: error)
        }
    }
    
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            if downloadTasks.count == 0 {
                
            }
        }
    }
    
}

