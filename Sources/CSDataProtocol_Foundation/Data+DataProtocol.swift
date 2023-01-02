//
//  Data+DataProtocol.swift
//  
//  Created by Charles Srstka on 11/13/22.
//

import Foundation
import CSDataProtocol

extension Data: CSDataProtocol.ContiguousBytes {}

extension Data: CSDataProtocol.DataProtocol {
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
        for region in slice.regions {
            guard amountToCopy > 0 else {
                break
            }

            region.withUnsafeBytes { buffer in
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

extension Data: CSDataProtocol.MutableDataProtocol {
    public mutating func resetBytes<R: RangeExpression>(in range: R) where R.Bound == Index {
        let r = range.relative(to: self)
        let count = distance(from: r.lowerBound, to: r.upperBound)
        replaceSubrange(r, with: repeatElement(UInt8(0), count: count))
    }
}
