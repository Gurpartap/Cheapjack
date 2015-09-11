// DownloadsCellViewModel.swift
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

class DownloadsCellViewModel: CheapjackDownloadDelegate {

	let info = MutableProperty<String>("")
	let progress = MutableProperty<Float>(0)
	let progressLabelText = MutableProperty<String>("")
	let state = MutableProperty<String>("")
	let nextAction = MutableProperty<DownloadsCellAction>(DownloadsCellAction.Download)

	func download(download: CheapjackDownload, progressChanged fractionCompleted: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		progress.value = fractionCompleted

		let formattedWrittenBytes = NSByteCountFormatter.stringFromByteCount(totalBytesWritten, countStyle: .File)
		let formattedTotalBytes = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: .File)
		progressLabelText.value = String(format: "\(formattedWrittenBytes) of \(formattedTotalBytes) (%.f %%)", progress.value * 100)
	}

	func download(download: CheapjackDownload, stateChanged toState: CheapjackDownloadState, fromState: CheapjackDownloadState) {
		switch toState {
		case .Waiting:
			state.value = "Waiting..."
			nextAction.value = DownloadsCellAction.Pause
		case .Downloading:
			state.value = "Downloading"
			nextAction.value = DownloadsCellAction.Pause
		case .Pausing:
			state.value = "Pausing..."
			nextAction.value = DownloadsCellAction.None
		case .Paused:
			state.value = "Paused"
			nextAction.value = DownloadsCellAction.Resume
		case .Completed:
			state.value = "Completed"
			nextAction.value = DownloadsCellAction.Remove
		case .Cancelled:
			state.value = "Cancelled"
			nextAction.value = DownloadsCellAction.Remove
		default:
			state.value = "Unknown"
			nextAction.value = .Download
		}
	}

}
