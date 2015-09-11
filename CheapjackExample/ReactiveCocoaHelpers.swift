// ReactiveCocoaHelpers.swift
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
import ReactiveCocoa

func willDeallocSignal(object: NSObject) -> SignalProducer<(), NoError> {
	return object.rac_willDeallocSignal().toSignalProducer()
		.map { _ in () }
		.flatMapError { _ in SignalProducer<(), NoError>.empty }
}

func textSignal(textField: UITextField) -> SignalProducer<String, NoError> {
	return textField.rac_textSignal().toSignalProducer()
		.map { $0! as! String }
		.flatMapError { _ in SignalProducer(value: "") }
}

func controlEventsSignal(control: UIControl, controlEvents: UIControlEvents) -> SignalProducer<UIControl, NoError> {
	return control.rac_signalForControlEvents(controlEvents).toSignalProducer()
		.map { $0! as! UIControl }
		.flatMapError { _ in SignalProducer<UIControl, NoError>.empty }
}

func prepareForReuseSignal(cell: UITableViewCell) -> SignalProducer<(), NoError> {
	return cell.rac_prepareForReuseSignal.toSignalProducer()
		.map { _ in () }
		.flatMapError { _ in SignalProducer<(), NoError>.empty }
}
