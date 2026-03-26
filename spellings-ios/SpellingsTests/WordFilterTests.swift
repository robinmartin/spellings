import XCTest
@testable import Spellings

final class WordFilterTests: XCTestCase {
    func testWordEntryDecodesOptionalBuckets() throws {
        let data = """
        {
          "word": "accompany",
          "master": 5,
          "au1": 1,
          "au2": null,
          "sp1": null,
          "sp2": 1,
          "su1": null,
          "su2": null,
          "ex1": null,
          "ex2": null,
          "ex3": null
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(WordEntry.self, from: data)

        XCTAssertEqual(entry.word, "accompany")
        XCTAssertEqual(entry.master, 5)
        XCTAssertEqual(entry.au1, 1)
        XCTAssertNil(entry.au2)
        XCTAssertEqual(entry.sp2, 1)
        XCTAssertNil(entry.ex3)
    }

    func testAllFilterReturnsAllWords() {
        let words = makeEntries()

        let result = WordFilter.all.filteredWords(from: words)

        XCTAssertEqual(result, ["alpha", "bravo", "charlie", "delta"])
    }

    func testLearnedFilterMatchesWebAppRules() {
        let words = makeEntries()

        let result = WordFilter.learned.filteredWords(from: words)

        XCTAssertEqual(result, ["alpha", "charlie"])
    }

    func testNotLearnedFilterMatchesWebAppRules() {
        let words = makeEntries()

        let result = WordFilter.notLearned.filteredWords(from: words)

        XCTAssertEqual(result, ["bravo", "delta"])
    }

    func testTermFilterReturnsWordsWithValuesForSelectedBucket() {
        let words = makeEntries()

        let result = WordFilter.sp2.filteredWords(from: words)

        XCTAssertEqual(result, ["charlie"])
    }

    private func makeEntries() -> [WordEntry] {
        [
            WordEntry(word: "alpha", master: 1, au1: 1, au2: nil, sp1: nil, sp2: nil, su1: nil, su2: nil, ex1: nil, ex2: nil, ex3: nil),
            WordEntry(word: "bravo", master: nil, au1: nil, au2: nil, sp1: nil, sp2: nil, su1: nil, su2: nil, ex1: 2, ex2: nil, ex3: nil),
            WordEntry(word: "charlie", master: 3, au1: nil, au2: nil, sp1: nil, sp2: 1, su1: nil, su2: nil, ex1: nil, ex2: nil, ex3: nil),
            WordEntry(word: "delta", master: nil, au1: nil, au2: nil, sp1: nil, sp2: nil, su1: nil, su2: nil, ex1: nil, ex2: nil, ex3: 1)
        ]
    }
}
