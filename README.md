# CSDataProtocol

An implementation of Foundation’s `DataProtocol` that does not require linking against Foundation.

This will allow library code to efficiently process byte buffers in generic functions without requiring clients to link against Foundation.

Most of the code is directly lifted from `swift-corelibs-foundation`, and as such, the license is Apache 2.0 to match.

Unlike the original, the code here is fully unit tested, which actually turned up a few bugs (which have been fixed).
I intend to make a PR for these fixes in `swift-corelibs-foundation` once I have some free time to do so.
