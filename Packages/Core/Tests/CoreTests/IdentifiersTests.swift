import Testing

@testable import Core

@Test func appGroupMatchesBundle() {
    #expect(Identifiers.appGroup == "group." + Identifiers.bundle)
}
