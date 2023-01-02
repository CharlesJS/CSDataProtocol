//
//  Collections+DataProtocol.swift
//  
//  Blatantly copied (with minor modifications) from:
//  https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/Collections%2BDataProtocol.swift
//

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
//===--- DataProtocol -----------------------------------------------------===//
extension Array: DataProtocol where Element == UInt8 {
    public var regions: CollectionOfOne<Array<UInt8>> {
        return CollectionOfOne(self)
    }
}

extension ArraySlice: DataProtocol where Element == UInt8 {
    public var regions: CollectionOfOne<ArraySlice<UInt8>> {
        return CollectionOfOne(self)
    }
}

extension ContiguousArray: DataProtocol where Element == UInt8 {
    public var regions: CollectionOfOne<ContiguousArray<UInt8>> {
        return CollectionOfOne(self)
    }
}

// FIXME: This currently crashes compilation in the Late Inliner.
// extension CollectionOfOne : DataProtocol where Element == UInt8 {
//     public typealias Regions = CollectionOfOne<Data>
//
//     public var regions: CollectionOfOne<Data> {
//         return CollectionOfOne<Data>(Data(self))
//     }
// }
extension EmptyCollection : DataProtocol where Element == UInt8 {
    public var regions: EmptyCollection<ContiguousArray<UInt8>> {
        return EmptyCollection<ContiguousArray<UInt8>>()
    }
}

extension Repeated: DataProtocol where Element == UInt8 {
    public typealias Regions = Repeated<ContiguousArray<UInt8>>

    public var regions: Repeated<ContiguousArray<UInt8>> {
        guard self.count > 0 else { return repeatElement(ContiguousArray<UInt8>(), count: 0) }
        return repeatElement(ContiguousArray(CollectionOfOne(self.first!)), count: self.count)
    }
}

//===--- MutableDataProtocol ----------------------------------------------===//
extension Array: MutableDataProtocol where Element == UInt8 { }

extension ContiguousArray: MutableDataProtocol where Element == UInt8 { }
