import Core
import SwiftUI
import Testing

@testable import Design

@Test func circuitRestIsYellowLikePreparation() {
    #expect(Palette.fill(.circuitRest) == Palette.fill(.preparation))
    #expect(Palette.fill(.circuitRest) != Palette.fill(.rest))
    #expect(Palette.fill(.active) != Palette.fill(.rest))
}

@Test func fontsShipInPackage() throws {
    let folder = try #require(Bundle.module.url(forResource: "Fonts", withExtension: nil))
    let names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
    #expect(names.filter { $0.hasSuffix(".ttf") }.count == 7)
    #expect(names.contains("OFL-Barlow.txt"))
}
