import XCTest
@testable import AppCore

/// Tag 테스트
/// - data-model.md A3 준수
final class TagTests: XCTestCase {

    // MARK: - Creation

    func testTag_Creation() {
        let tag = Tag(name: "Work")

        XCTAssertFalse(tag.id.isEmpty)
        XCTAssertEqual(tag.name, "Work")
        XCTAssertNil(tag.colorToken)
    }

    func testTag_WithColorToken() {
        let tag = Tag(name: "Urgent", colorToken: "red")

        XCTAssertEqual(tag.colorToken, "red")
        XCTAssertTrue(tag.hasValidColorToken)
    }

    // MARK: - Name Normalization

    func testNormalizedName() {
        let tag = Tag(name: "  Work  ")

        XCTAssertEqual(tag.normalizedName, "work")
    }

    func testNameMatches_CaseInsensitive() {
        let tag = Tag(name: "Work")

        XCTAssertTrue(tag.nameMatches("work"))
        XCTAssertTrue(tag.nameMatches("WORK"))
        XCTAssertTrue(tag.nameMatches("Work"))
        XCTAssertTrue(tag.nameMatches("  work  "))
        XCTAssertFalse(tag.nameMatches("working"))
    }

    // MARK: - Display

    func testDisplayLabel() {
        let tag = Tag(name: "urgent")

        XCTAssertEqual(tag.displayLabel, "#urgent")
    }

    // MARK: - Parsing (QuickAdd)

    func testParseTagName_Valid() {
        XCTAssertEqual(Tag.parseTagName(from: "#work"), "work")
        XCTAssertEqual(Tag.parseTagName(from: "#urgent"), "urgent")
        XCTAssertEqual(Tag.parseTagName(from: "  #tag  "), "tag")
        XCTAssertEqual(Tag.parseTagName(from: "#한글태그"), "한글태그")
    }

    func testParseTagName_Invalid() {
        XCTAssertNil(Tag.parseTagName(from: "work")) // no #
        XCTAssertNil(Tag.parseTagName(from: "#")) // empty after #
        XCTAssertNil(Tag.parseTagName(from: "#  ")) // only whitespace after #
        XCTAssertNil(Tag.parseTagName(from: "")) // empty
    }

    // MARK: - Color Token

    func testDefaultColorTokens() {
        XCTAssertTrue(Tag.defaultColorTokens.contains("red"))
        XCTAssertTrue(Tag.defaultColorTokens.contains("blue"))
        XCTAssertFalse(Tag.defaultColorTokens.contains("magenta"))
    }

    func testHasValidColorToken() {
        let validTag = Tag(name: "Test", colorToken: "blue")
        let invalidTag = Tag(name: "Test", colorToken: "magenta")
        let noColorTag = Tag(name: "Test")

        XCTAssertTrue(validTag.hasValidColorToken)
        XCTAssertFalse(invalidTag.hasValidColorToken)
        XCTAssertFalse(noColorTag.hasValidColorToken)
    }

    // MARK: - Array Extensions

    func testFindByName() {
        let tags = [
            Tag(name: "Work"),
            Tag(name: "Personal"),
            Tag(name: "Urgent")
        ]

        let found = tags.find(byName: "WORK")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Work")

        XCTAssertNil(tags.find(byName: "nonexistent"))
    }

    func testContainsName() {
        let tags = [
            Tag(name: "Work"),
            Tag(name: "Personal")
        ]

        XCTAssertTrue(tags.containsName("work"))
        XCTAssertTrue(tags.containsName("PERSONAL"))
        XCTAssertFalse(tags.containsName("urgent"))
    }

    func testFilterByIds() {
        let tag1 = Tag(id: "t1", name: "Work")
        let tag2 = Tag(id: "t2", name: "Personal")
        let tag3 = Tag(id: "t3", name: "Urgent")
        let tags = [tag1, tag2, tag3]

        let filtered = tags.filter(byIds: ["t1", "t3"])

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains { $0.id == "t1" })
        XCTAssertTrue(filtered.contains { $0.id == "t3" })
    }

    func testSortedByName() {
        let tags = [
            Tag(name: "Zebra"),
            Tag(name: "apple"),
            Tag(name: "Banana")
        ]

        let sorted = tags.sortedByName()

        XCTAssertEqual(sorted.map(\.name), ["apple", "Banana", "Zebra"])
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        let tag = Tag(
            id: "tag-1",
            name: "Important",
            colorToken: "red"
        )

        let data = try JSONEncoder().encode(tag)
        let decoded = try JSONDecoder().decode(Tag.self, from: data)

        XCTAssertEqual(decoded.id, tag.id)
        XCTAssertEqual(decoded.name, tag.name)
        XCTAssertEqual(decoded.colorToken, tag.colorToken)
    }

    func testCodable_WithoutColorToken() throws {
        let tag = Tag(name: "Simple")

        let data = try JSONEncoder().encode(tag)
        let decoded = try JSONDecoder().decode(Tag.self, from: data)

        XCTAssertEqual(decoded.name, tag.name)
        XCTAssertNil(decoded.colorToken)
    }

    // MARK: - Equatable

    func testEquatable() {
        let tag1 = Tag(id: "t1", name: "Work")
        let tag2 = Tag(id: "t1", name: "Work")
        let tag3 = Tag(id: "t2", name: "Work")

        XCTAssertEqual(tag1, tag2)
        XCTAssertNotEqual(tag1, tag3)
    }
}
