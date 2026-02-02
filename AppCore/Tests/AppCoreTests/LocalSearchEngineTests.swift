import XCTest
@testable import AppCore

final class LocalSearchEngineTests: XCTestCase {

    private var engine: LocalSearchEngine!

    override func setUp() {
        super.setUp()
        engine = LocalSearchEngine()
    }

    // MARK: - Empty Query Tests

    func test_emptyQuery_returnsEmptyResults() {
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task")

        let results = engine.search(
            query: "",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: []
        )

        XCTAssertTrue(results.isEmpty)
    }

    func test_whitespaceOnlyQuery_returnsEmptyResults() {
        let project = Project(id: "p1", title: "Test", startDate: Date())

        let results = engine.search(
            query: "   ",
            projects: [project],
            tasks: [],
            tags: [],
            sections: []
        )

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Project Search Tests

    func test_projectSearch_findsByTitle() {
        let project1 = Project(id: "p1", title: "Work Project", startDate: Date())
        let project2 = Project(id: "p2", title: "Personal Project", startDate: Date())

        let results = engine.search(
            query: "work",
            projects: [project1, project2],
            tasks: [],
            tags: [],
            sections: []
        )

        XCTAssertEqual(results.projects.count, 1)
        XCTAssertEqual(results.projects.first?.id, "p1")
    }

    func test_projectSearch_caseInsensitive() {
        let project = Project(id: "p1", title: "IMPORTANT Project", startDate: Date())

        let results = engine.search(
            query: "important",
            projects: [project],
            tasks: [],
            tags: [],
            sections: []
        )

        XCTAssertEqual(results.projects.count, 1)
    }

    func test_projectSearch_findsByNote() {
        let project = Project(
            id: "p1",
            title: "Work",
            startDate: Date(),
            note: "This is about marketing campaign"
        )

        let results = engine.search(
            query: "marketing",
            projects: [project],
            tasks: [],
            tags: [],
            sections: [],
            options: .default
        )

        XCTAssertEqual(results.projects.count, 1)
        XCTAssertEqual(results.projects.first?.subtitle, "노트에서 발견")
    }

    // MARK: - Task Search Tests

    func test_taskSearch_findsByTitle() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task1 = Task(id: "t1", projectId: "p1", title: "Review PR")
        let task2 = Task(id: "t2", projectId: "p1", title: "Write tests")

        let results = engine.search(
            query: "review",
            projects: [project],
            tasks: [task1, task2],
            tags: [],
            sections: []
        )

        XCTAssertEqual(results.tasks.count, 1)
        XCTAssertEqual(results.tasks.first?.id, "t1")
    }

    func test_taskSearch_includesProjectNameAsSubtitle() {
        let project = Project(id: "p1", title: "Work Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Review PR")

        let results = engine.search(
            query: "review",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: []
        )

        XCTAssertEqual(results.tasks.first?.subtitle, "Work Project")
    }

    func test_taskSearch_findsByNote() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Meeting", note: "Discuss with John")

        let results = engine.search(
            query: "john",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: []
        )

        XCTAssertEqual(results.tasks.count, 1)
        XCTAssertTrue(results.tasks.first?.subtitle?.contains("노트에서 발견") ?? false)
    }

    // MARK: - Tag Search Tests

    func test_tagSearch_findsByName() {
        let tag1 = Tag(id: "tag1", name: "work")
        let tag2 = Tag(id: "tag2", name: "personal")

        let results = engine.search(
            query: "work",
            projects: [],
            tasks: [],
            tags: [tag1, tag2],
            sections: []
        )

        XCTAssertEqual(results.tags.count, 1)
        XCTAssertEqual(results.tags.first?.id, "tag1")
    }

    // MARK: - Section Search Tests

    func test_sectionSearch_findsByTitle() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let section1 = Section(id: "s1", projectId: "p1", title: "In Progress")
        let section2 = Section(id: "s2", projectId: "p1", title: "Done")

        let results = engine.search(
            query: "progress",
            projects: [project],
            tasks: [],
            tags: [],
            sections: [section1, section2]
        )

        XCTAssertEqual(results.sections.count, 1)
        XCTAssertEqual(results.sections.first?.id, "s1")
    }

    // MARK: - Search Options Tests

    func test_tasksOnlyOption_searchesOnlyTasks() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Work task")

        let results = engine.search(
            query: "work",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: [],
            options: .tasksOnly
        )

        XCTAssertTrue(results.projects.isEmpty)
        XCTAssertEqual(results.tasks.count, 1)
    }

    func test_projectsOnlyOption_searchesOnlyProjects() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Work task")

        let results = engine.search(
            query: "work",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: [],
            options: .projectsOnly
        )

        XCTAssertEqual(results.projects.count, 1)
        XCTAssertTrue(results.tasks.isEmpty)
    }

    func test_maxResultsPerType_limitsResults() {
        var tasks: [Task] = []
        for i in 1...30 {
            tasks.append(Task(id: "t\(i)", projectId: "p1", title: "Task \(i)"))
        }
        let project = Project(id: "p1", title: "Work", startDate: Date())

        let options = LocalSearchEngine.SearchOptions(maxResultsPerType: 5)
        let results = engine.search(
            query: "task",
            projects: [project],
            tasks: tasks,
            tags: [],
            sections: [],
            options: options
        )

        XCTAssertEqual(results.tasks.count, 5)
    }

    func test_includeNotesFalse_skipsNoteSearch() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Meeting", note: "keyword here")

        let options = LocalSearchEngine.SearchOptions(includeNotes: false)
        let results = engine.search(
            query: "keyword",
            projects: [project],
            tasks: [task],
            tags: [],
            sections: [],
            options: options
        )

        XCTAssertTrue(results.tasks.isEmpty)
    }

    // MARK: - Quick Search Tests

    func test_quickSearch_returnsLimitedTaskResults() {
        var tasks: [Task] = []
        for i in 1...10 {
            tasks.append(Task(id: "t\(i)", projectId: "p1", title: "Task \(i)"))
        }
        let project = Project(id: "p1", title: "Work", startDate: Date())

        let results = engine.quickSearch(
            query: "task",
            tasks: tasks,
            projects: [project]
        )

        XCTAssertEqual(results.count, 5) // 최대 5개
    }

    // MARK: - Match Ranges Tests

    func test_matchRanges_correctlyIdentified() {
        let project = Project(id: "p1", title: "Work Project", startDate: Date())

        let results = engine.search(
            query: "work",
            projects: [project],
            tasks: [],
            tags: [],
            sections: []
        )

        guard let firstResult = results.projects.first else {
            XCTFail("Expected project result")
            return
        }

        XCTAssertFalse(firstResult.matchRanges.isEmpty)

        // "Work" in "Work Project"
        if let range = firstResult.matchRanges.first {
            let matchedText = String(firstResult.title[range])
            XCTAssertEqual(matchedText.lowercased(), "work")
        }
    }

    // MARK: - Total Count Tests

    func test_totalCount_sumsAllResults() {
        let project = Project(id: "p1", title: "Work", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Work task")
        let tag = Tag(id: "tag1", name: "work")
        let section = Section(id: "s1", projectId: "p1", title: "Work section")

        let results = engine.search(
            query: "work",
            projects: [project],
            tasks: [task],
            tags: [tag],
            sections: [section]
        )

        XCTAssertEqual(results.totalCount, 4)
    }
}
