//
//  DispatchData+DataProtocol.swift
//
//  Blatantly copied (with minor modifications) from:
//  https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/DispatchData%2BDataProtocol.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Dispatch
import CSDataProtocol

extension DispatchData.Region: CSDataProtocol.ContiguousBytes {}

extension DispatchData.Region: CSDataProtocol.DataProtocol {
    @discardableResult
    public func copyBytes(to ptr: UnsafeMutableRawBufferPointer, count: Int) -> Int {
        return copyBytes(to: ptr, from: self.startIndex ..< self.index(self.startIndex, offsetBy: count))
    }

    @discardableResult
    public func copyBytes<DestinationType>(to ptr: UnsafeMutableBufferPointer<DestinationType>, count: Int) -> Int {
        return copyBytes(to: ptr, from: self.startIndex ..< self.index(self.startIndex, offsetBy: count))
    }

    @discardableResult
    public func copyBytes<R: RangeExpression>(to ptr: UnsafeMutableRawBufferPointer, from range: R) -> Int where R.Bound == Index {
        precondition(ptr.baseAddress != nil)

        let concreteRange = range.relative(to: self)

        let rangeCount = distance(from: concreteRange.lowerBound, to: concreteRange.upperBound)
        let offset = distance(from: self.startIndex, to: concreteRange.lowerBound)
        let amountToCopy = Swift.min(ptr.count, rangeCount)
        guard amountToCopy > 0 else {
            return 0
        }

        return self.withUnsafeBytes { buffer in
            // bug fix: version in swift-corelibs-foundation just uses buffer.baseAddress without adding the offset
            let buf = UnsafeRawBufferPointer(start: buffer.baseAddress! + offset, count: Swift.min(buffer.count, amountToCopy))
            ptr.copyMemory(from: buf)

            return buf.count
        }
    }

    @discardableResult
    public func copyBytes<DestinationType, R: RangeExpression>(to ptr: UnsafeMutableBufferPointer<DestinationType>, from range: R) -> Int where R.Bound == Index {
        return self.copyBytes(to: UnsafeMutableRawBufferPointer(start: ptr.baseAddress, count: ptr.count * MemoryLayout<DestinationType>.stride), from: range)
    }
}

extension DispatchData : CSDataProtocol.DataProtocol {
    @discardableResult
    public func copyBytes(to ptr: UnsafeMutableRawBufferPointer, count: Int) -> Int {
        return copyBytes(to: ptr, from: self.startIndex ..< self.index(self.startIndex, offsetBy: count))
    }

    @discardableResult
    public func copyBytes<DestinationType>(to ptr: UnsafeMutableBufferPointer<DestinationType>, count: Int) -> Int {
        return copyBytes(to: ptr, from: self.startIndex ..< self.index(self.startIndex, offsetBy: count))
    }

    @discardableResult
    public func copyBytes<R: RangeExpression>(to ptr: UnsafeMutableRawBufferPointer, from range: R) -> Int where R.Bound == Index {
        precondition(ptr.baseAddress != nil)

        let concreteRange = range.relative(to: self)
        let slice = self[concreteRange]

        // The type isn't contiguous, so we need to copy one region at a time.
        var offset = 0
        let rangeCount = distance(from: concreteRange.lowerBound, to: concreteRange.upperBound)
        var amountToCopy = Swift.min(ptr.count, rangeCount)
        for region in slice._regions {
            guard amountToCopy > 0 else {
                break
            }

            region._withUnsafeBytes { buffer in
                let offsetPtr = UnsafeMutableRawBufferPointer(rebasing: ptr[offset...])
                let buf = UnsafeRawBufferPointer(start: buffer.baseAddress, count: Swift.min(buffer.count, amountToCopy))
                offsetPtr.copyMemory(from: buf)
                offset += buf.count
                amountToCopy -= buf.count
            }
        }

        return offset
    }

    @discardableResult
    public func copyBytes<DestinationType, R: RangeExpression>(to ptr: UnsafeMutableBufferPointer<DestinationType>, from range: R) -> Int where R.Bound == Index {
        return self.copyBytes(to: UnsafeMutableRawBufferPointer(start: ptr.baseAddress, count: ptr.count * MemoryLayout<DestinationType>.stride), from: range)
    }
}
