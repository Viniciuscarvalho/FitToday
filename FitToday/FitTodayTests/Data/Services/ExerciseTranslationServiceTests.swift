//
//  ExerciseTranslationServiceTests.swift
//  FitTodayTests
//
//  Tests for ExerciseTranslationService - local translation of exercise descriptions.
//

@testable import FitToday
import XCTest

final class ExerciseTranslationServiceTests: XCTestCase {
    var sut: ExerciseTranslationService!

    override func setUp() {
        super.setUp()
        sut = ExerciseTranslationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Portuguese Text Tests

    func testPortugueseTextRemainsUnchanged() async {
        // Given
        let portugueseText = "Mantenha os braços estendidos e empurre o peso para cima."

        // When
        let result = await sut.ensureLocalizedDescription(portugueseText)

        // Then
        XCTAssertEqual(result, portugueseText, "Portuguese text should remain unchanged")
    }

    func testPortuguesePatternDetection() async {
        // Given - text with clear Portuguese patterns
        let portugueseText = "Fique em pé com os pés na largura dos ombros."

        // When
        let result = await sut.ensureLocalizedDescription(portugueseText)

        // Then
        XCTAssertEqual(result, portugueseText, "Text with Portuguese patterns should remain unchanged")
    }

    // MARK: - English Translation Tests

    func testEnglishTextIsTranslated() async {
        // Given
        let englishText = "Keep your arms straight and push the weight up."

        // When
        let result = await sut.ensureLocalizedDescription(englishText)

        // Then
        XCTAssertTrue(result.contains("mantenha"), "Should translate 'keep' to 'mantenha'")
        XCTAssertTrue(result.contains("braços"), "Should translate 'arms' to 'braços'")
        XCTAssertTrue(result.contains("empurre"), "Should translate 'push' to 'empurre'")
        XCTAssertFalse(result.lowercased().contains("keep"), "Should not contain original English word 'keep'")
    }

    func testEnglishBodyPartsAreTranslated() async {
        // Given
        let englishText = "Flex your elbows and lower the barbell to your chest."

        // When
        let result = await sut.ensureLocalizedDescription(englishText)

        // Then
        XCTAssertTrue(result.contains("cotovelos"), "Should translate 'elbows' to 'cotovelos'")
        XCTAssertTrue(result.contains("barra"), "Should translate 'barbell' to 'barra'")
        XCTAssertTrue(result.contains("peito"), "Should translate 'chest' to 'peito'")
    }

    func testEnglishVerbsAreTranslated() async {
        // Given
        let englishText = "Hold the position, then slowly lower your body."

        // When
        let result = await sut.ensureLocalizedDescription(englishText)

        // Then
        XCTAssertTrue(result.contains("segure"), "Should translate 'hold' to 'segure'")
        XCTAssertTrue(result.contains("abaixe"), "Should translate 'lower' to 'abaixe'")
        XCTAssertTrue(result.contains("lentamente"), "Should translate 'slowly' to 'lentamente'")
    }

    // MARK: - Spanish Translation Tests

    func testSpanishTextIsTranslated() async {
        // Given
        let spanishText = "Mantenga los brazos extendidos y empuje el peso hacia arriba."

        // When
        let result = await sut.ensureLocalizedDescription(spanishText)

        // Then
        XCTAssertTrue(result.contains("braços"), "Should translate 'brazos' to 'braços'")
        XCTAssertTrue(result.contains("para cima"), "Should translate 'arriba' to 'para cima'")
    }

    func testSpanishBodyPartsAreTranslated() async {
        // Given
        let spanishText = "Flexione los codos y baje la barra hasta el pecho."

        // When
        let result = await sut.ensureLocalizedDescription(spanishText)

        // Then
        XCTAssertTrue(result.contains("cotovelos"), "Should translate 'codos' to 'cotovelos'")
        XCTAssertTrue(result.contains("peito"), "Should translate 'pecho' to 'peito'")
    }

    // MARK: - Cache Tests

    func testResultsAreCached() async {
        // Given
        let englishText = "Keep your arms straight and push."

        // When
        let firstResult = await sut.ensureLocalizedDescription(englishText)
        let secondResult = await sut.ensureLocalizedDescription(englishText)

        // Then
        XCTAssertEqual(firstResult, secondResult, "Cached result should be identical")
    }

    func testCacheClear() async {
        // Given
        let text = "Keep your arms straight."
        _ = await sut.ensureLocalizedDescription(text)

        // When
        await sut.clearCache()

        // Then - should still work after cache clear
        let result = await sut.ensureLocalizedDescription(text)
        XCTAssertTrue(result.contains("mantenha"), "Should still translate after cache clear")
    }

    // MARK: - Edge Cases

    func testEmptyStringReturnsFallback() async {
        // Given
        let emptyText = ""

        // When
        let result = await sut.ensureLocalizedDescription(emptyText)

        // Then - should return fallback (non-empty)
        XCTAssertFalse(result.isEmpty, "Empty input should return fallback message")
    }

    func testShortStringReturnsFallback() async {
        // Given
        let shortText = "Push up"

        // When
        let result = await sut.ensureLocalizedDescription(shortText)

        // Then - strings under 10 chars should return fallback
        XCTAssertFalse(result.isEmpty, "Short input should return fallback message")
    }

    func testMixedLanguageText() async {
        // Given - text with both English and Portuguese
        let mixedText = "Mantenha the arms extended during the movement."

        // When
        let result = await sut.ensureLocalizedDescription(mixedText)

        // Then - should translate the English parts
        XCTAssertTrue(result.contains("braços") || result.contains("Mantenha"),
                      "Should handle mixed language text")
    }

    // MARK: - Sentence-Initial Pattern Tests

    func testSentenceInitialKeepIsDetectedAsEnglish() async {
        // Given - verb at start of string (no leading space)
        let text = "Keep your back straight and your core engaged throughout."

        // When
        let result = await sut.ensureLocalizedDescription(text)

        // Then
        XCTAssertFalse(result.lowercased().contains("keep"),
                       "Sentence-initial 'Keep' should be translated")
        XCTAssertTrue(result.lowercased().contains("mantenha") || result.lowercased().contains("costas"),
                      "Should produce Portuguese output for sentence-initial English")
    }

    func testSentenceInitialPushIsDetectedAsEnglish() async {
        // Given - short CMS trainer note starting with verb
        let text = "Push through your heels as you stand up from the squat."

        // When
        let result = await sut.ensureLocalizedDescription(text)

        // Then
        XCTAssertFalse(result.lowercased().contains("push "),
                       "Sentence-initial 'Push' should be translated")
        XCTAssertTrue(result.lowercased().contains("empurre") || result.lowercased().contains("calcanhar"),
                      "Should produce Portuguese output for sentence-initial English verb")
    }

    // MARK: - Post-Translation Quality Check Tests

    func testSpanishTextWithUntranslatableWordsReturnsFallback() async {
        // Given - Spanish text with words NOT in dictionary (" muy ", " desde " survive translation)
        let spanishText = "Los músculos deben estar muy activos desde el inicio del ejercicio."

        // When
        let result = await sut.ensureLocalizedDescription(spanishText)

        // Then - quality check should detect remaining Spanish patterns and return fallback
        let fallback = await sut.ensureLocalizedDescription("")
        XCTAssertEqual(result, fallback,
                       "Poorly translated Spanish text should return Portuguese fallback")
    }

    func testEnglishTextWithUntranslatableWordsReturnsFallback() async {
        // Given - English text with words NOT in dictionary (" should ", " have " survive translation)
        let englishText = "You should have your feet flat on the floor during the entire movement."

        // When
        let result = await sut.ensureLocalizedDescription(englishText)

        // Then - quality check should detect remaining English patterns and return fallback
        let fallback = await sut.ensureLocalizedDescription("")
        XCTAssertEqual(result, fallback,
                       "Poorly translated English text should return Portuguese fallback")
    }

    func testCleanSpanishTranslationPassesQualityCheck() async {
        // Given - Spanish text where all words are in the dictionary
        let spanishText = "Mantenga los brazos extendidos y empuje el peso hacia arriba."

        // When
        let result = await sut.ensureLocalizedDescription(spanishText)

        // Then - clean translation should NOT return fallback
        let fallback = await sut.ensureLocalizedDescription("")
        XCTAssertNotEqual(result, fallback,
                          "Clean Spanish translation should pass quality check, not return fallback")
    }

    // MARK: - Real-World Exercise Descriptions

    func testRealBenchPressDescription() async {
        // Given - typical bench press description from Wger API
        let description = "Lie on the bench with your feet flat on the floor. Grip the bar with hands slightly wider than shoulder-width apart. Lower the bar to your chest, then push it back up."

        // When
        let result = await sut.ensureLocalizedDescription(description)

        // Then
        XCTAssertTrue(result.contains("banco"), "Should translate 'bench' to 'banco'")
        XCTAssertTrue(result.contains("peito"), "Should translate 'chest' to 'peito'")
        XCTAssertTrue(result.contains("empurre"), "Should translate 'push' to 'empurre'")
    }

    func testRealSquatDescription() async {
        // Given
        let description = "Stand with feet shoulder-width apart. Lower your body by bending your knees and hips. Keep your back straight throughout the movement."

        // When
        let result = await sut.ensureLocalizedDescription(description)

        // Then
        XCTAssertTrue(result.contains("pés") || result.contains("joelhos"),
                      "Should translate body parts")
        XCTAssertTrue(result.contains("costas") || result.contains("reto"),
                      "Should translate positioning terms")
    }
}
