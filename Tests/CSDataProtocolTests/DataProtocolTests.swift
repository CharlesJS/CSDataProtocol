import XCTest
@testable import CSDataProtocol
@testable import CSDataProtocol_Foundation

final class DataProtocolTests: XCTestCase {
    private func convertToString(bytes: some CSDataProtocol.ContiguousBytes) -> String {
        bytes.withUnsafeBytes { String(decoding: $0, as: UTF8.self) }
    }

    private func checkData(_ data: some CSDataProtocol.DataProtocol) {
        XCTAssertEqual(data.regions.map { self.convertToString(bytes: $0) }.joined(), "Foo Bar Bar")

        let barRange1 = data.index(data.startIndex, offsetBy: 4)..<data.index(data.startIndex, offsetBy: 7)
        let barRange2 = data.index(data.startIndex, offsetBy: 8)..<data.index(data.startIndex, offsetBy: 11)

        XCTAssertEqual(data.firstRange(of: [0x42, 0x61, 0x72]), barRange1)
        XCTAssertNil(data.firstRange(of: [1, 2, 3]))
        XCTAssertNil(data.firstRange(of: [1]))
        XCTAssertNil(data.firstRange(of: []))
        XCTAssertNil(data.firstRange(of: [0x42], in: data.startIndex..<data.startIndex))
        XCTAssertNil(data.firstRange(of: [0x42], in: data.endIndex..<data.endIndex))

        XCTAssertEqual(data.lastRange(of: [0x42, 0x61, 0x72]), barRange2)
        XCTAssertNil(data.lastRange(of: [1, 2, 3]))
        XCTAssertNil(data.lastRange(of: [1]))
        XCTAssertNil(data.lastRange(of: []))
        XCTAssertNil(data.lastRange(of: [0x42], in: data.startIndex..<data.startIndex))

        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 11)
        defer { buffer.deallocate() }

        let rawBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 11, alignment: 1)
        defer { rawBuffer.deallocate() }

        buffer.initialize(repeating: 0)
        data.copyBytes(to: buffer, count: 3)
        XCTAssertEqual(Data(buffer), Data([0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0, 0, 0, 0]))
        data.copyBytes(to: buffer, from: barRange1)
        XCTAssertEqual(Data(buffer), Data([0x42, 0x61, 0x72, 0, 0, 0, 0, 0, 0, 0, 0]))
        data.copyBytes(to: buffer)
        XCTAssertEqual(Data(buffer), Data(data))

        rawBuffer.initializeMemory(as: UInt8.self, repeating: 0)
        data.copyBytes(to: rawBuffer, count: 3)
        XCTAssertEqual(Data(rawBuffer), Data([0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0, 0, 0, 0]))
        data.copyBytes(to: rawBuffer, from: barRange1)
        XCTAssertEqual(Data(rawBuffer), Data([0x42, 0x61, 0x72, 0, 0, 0, 0, 0, 0, 0, 0]))
        data.copyBytes(to: rawBuffer)
        XCTAssertEqual(Data(rawBuffer), Data(data))

        buffer.initialize(repeating: 0)
        data.copyBytes(to: UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: 0))
        XCTAssertEqual(Data(buffer), Data([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
        data.copyBytes(to: UnsafeMutableBufferPointer(start: buffer.baseAddress! + 3, count: 3))
        XCTAssertEqual(Data(buffer), Data([0, 0, 0, 0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0]))
        data.copyBytes(
            to: buffer,
            from: data.index(data.startIndex, offsetBy: 4)..<data.index(data.startIndex, offsetBy: 7)
        )
        XCTAssertEqual(Data(buffer), Data([0x42, 0x61, 0x72, 0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0]))
    }

    private func checkDispatchData(_ byteRegions: [[UInt8]], range: Range<Int>? = nil) {
        let data = byteRegions.first!.withUnsafeBytes {
            byteRegions.dropFirst(1).reduce(into: DispatchData(bytes: $0)) { data, bytes in
                bytes.withUnsafeBytes { data.append($0) }
            }
        }

        XCTAssertEqual(data.regions.count, byteRegions.count)

        if let range {
            let lowerBound = data.index(data.startIndex, offsetBy: range.lowerBound)
            let upperBound = data.index(data.startIndex, offsetBy: range.upperBound)

            self.checkData(data[lowerBound..<upperBound])
        } else {
            self.checkData(data)
        }
    }

    private func checkMutableData(_ _data: some CSDataProtocol.MutableDataProtocol) {
        var data = _data

        XCTAssertEqual(Data(data), Data([0x46, 0x6f, 0x6f, 0x20, 0x42, 0x61, 0x72]))

        data.resetBytes(in: data.index(data.startIndex, offsetBy: 2)..<data.index(data.startIndex, offsetBy: 5))
        XCTAssertEqual(Data(data), Data([0x46, 0x6f, 0, 0, 0, 0x61, 0x72]))

        data.resetBytes(in: data.startIndex..<data.endIndex)
        XCTAssertEqual(Data(data), Data([0, 0, 0, 0, 0, 0, 0]))
    }

    func testContiguousBytes() {
        var bytes: [UInt8] = [0x46, 0x6f, 0x6f, 0x20, 0x42, 0x61, 0x72]

        XCTAssertEqual(self.convertToString(bytes: bytes), "Foo Bar")
        XCTAssertEqual(self.convertToString(bytes: bytes[4..<7]), "Bar")
        XCTAssertEqual(self.convertToString(bytes: ContiguousArray(bytes)), "Foo Bar")
        XCTAssertEqual(self.convertToString(bytes: Slice(base: bytes, bounds: 4..<7)), "Bar")

        XCTAssertEqual(bytes.withUnsafeBytes { self.convertToString(bytes: $0) }, "Foo Bar")
        XCTAssertEqual(bytes.withUnsafeBytes { self.convertToString(bytes: $0.bindMemory(to: UInt8.self)) }, "Foo Bar")
        XCTAssertEqual(bytes.withUnsafeMutableBytes { self.convertToString(bytes: $0) }, "Foo Bar")
        XCTAssertEqual(bytes.withUnsafeMutableBytes { self.convertToString(bytes: $0.bindMemory(to: UInt8.self)) }, "Foo Bar")

        XCTAssertEqual(self.convertToString(bytes: EmptyCollection()), "")
        XCTAssertEqual(self.convertToString(bytes: CollectionOfOne(0x21)), "!")

        struct MyBytes: CSDataProtocol.DataProtocol, CSDataProtocol.ContiguousBytes {
            typealias Element = UInt8
            typealias Index = Array<UInt8>.Index
            typealias Indices = Array<UInt8>.Indices
            typealias Regions = Array<UInt8>.Regions
            typealias Subsequence = Array<UInt8>.SubSequence

            let bytes: [UInt8]
            init(_ bytes: [UInt8]) { self.bytes = bytes }
            var regions: Array<UInt8>.Regions { Array<UInt8>.Regions(self.bytes) }
            func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
                try self.bytes.withUnsafeBytes(body)
            }

            subscript(position: Array<UInt8>.Index) -> UInt8 { self.bytes[position] }
            var startIndex: Array<UInt8>.Index { self.bytes.startIndex }
            var endIndex: Array<UInt8>.Index { self.bytes.endIndex }
        }

        let myBytes = MyBytes(bytes)
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 11)
        defer { buffer.deallocate() }

        // To shut up the coverage check for this file
        XCTAssertEqual(myBytes[0], 0x46)

        buffer.initialize(repeating: 0)
        myBytes.copyBytes(to: UnsafeMutableBufferPointer(start: buffer.baseAddress!, count: 0))
        XCTAssertEqual(Data(buffer), Data([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
        myBytes.copyBytes(to: UnsafeMutableBufferPointer(start: buffer.baseAddress! + 3, count: 3))
        XCTAssertEqual(Data(buffer), Data([0, 0, 0, 0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0]))
        myBytes.copyBytes(
            to: buffer,
            from: myBytes.index(myBytes.startIndex, offsetBy: 4)..<myBytes.index(myBytes.startIndex, offsetBy: 7)
        )
        XCTAssertEqual(Data(buffer), Data([0x42, 0x61, 0x72, 0x46, 0x6f, 0x6f, 0, 0, 0, 0, 0]))
    }

    func testContiguousData() {
        let bytes: [UInt8] = [0x46, 0x6f, 0x6f, 0x20, 0x42, 0x61, 0x72, 0x20, 0x42, 0x61, 0x72]

        self.checkData(bytes)
        self.checkData((bytes + bytes + bytes)[11..<22])
        self.checkData(ContiguousArray(bytes))
        self.checkData(Slice(base: bytes + bytes + bytes, bounds: 11..<22))
        self.checkData(Data(bytes))
        self.checkData(bytes.withUnsafeBytes { DispatchData(bytes: $0) })

        bytes.withUnsafeBytes { self.checkData($0) }
        bytes.withUnsafeBytes { self.checkData($0.bindMemory(to: UInt8.self)) }

        let dispatchData = bytes.withUnsafeBytes {
            var dispatchData = DispatchData(bytes: $0)
            dispatchData.append($0)
            return dispatchData
        }
        XCTAssertEqual(dispatchData.regions.count, 2)
        for eachRegion in dispatchData.regions {
            self.checkData(eachRegion)
        }
    }

    func testDispatchData() {
        self.checkDispatchData([[0x46, 0x6f, 0x6f], [0x20, 0x42, 0x61], [0x72, 0x20], [0x42, 0x61, 0x72]])
        self.checkDispatchData(
            [[1, 2, 3], [4, 0x46, 0x6f, 0x6f, 0x20], [0x42, 0x61, 0x72, 0x20], [0x42, 0x61, 0x72, 3, 4], [5, 6]],
            range: 4..<15
        )
    }

    func testMutableData() {
        let bytes: [UInt8] = [0x46, 0x6f, 0x6f, 0x20, 0x42, 0x61, 0x72]

        self.checkMutableData(bytes)
        self.checkMutableData(ContiguousArray(bytes))
        self.checkMutableData(Data(bytes))
    }

    func testEmptyCollectionRegions() {
        XCTAssertEqual(self.getRegions(EmptyCollection<UInt8>()), EmptyCollection<ContiguousArray<UInt8>>())
    }

    func testEmptyRepeatedRegions() {
        let regions = self.getRegions(repeatElement(0 as UInt8, count: 0))

        XCTAssertEqual(regions.count, 0)
    }

    func testRepeatedRegions() {
        let collection = repeatElement(1 as UInt8, count: 3)
        let regions = self.getRegions(collection)

        XCTAssertEqual(regions.count, 3)
        XCTAssertEqual(regions.repeatedValue, ContiguousArray<UInt8>([1]))
    }

    // helper func to ensure that we use `regions` from `CSDataProtocol`, and not from Foundation's implementation
    private func getRegions<T: CSDataProtocol.DataProtocol>(_ collection: T) -> T.Regions { collection.regions }
}
