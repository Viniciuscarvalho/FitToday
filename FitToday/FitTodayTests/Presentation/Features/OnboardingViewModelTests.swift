//
//  OnboardingViewModelTests.swift
//  FitTodayTests
//
//  Created by AI on 08/01/26.
//

import XCTest
@testable import FitToday

final class OnboardingViewModelTests: XCTestCase {
    
    var mockRepository: MockOUserProfileRepository!
    var useCase: CreateOrUpdateProfileUseCase!
    var viewModel: OnboardingFlowViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockOUserProfileRepository()
        useCase = CreateOrUpdateProfileUseCase(repository: mockRepository)
        viewModel = OnboardingFlowViewModel(createProfileUseCase: useCase)
    }
    
    override func tearDown() {
        viewModel = nil
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Progressive Mode Tests
    
    @MainActor
    func testCanSubmitProgressiveRequiresGoalAndStructure() {
        // Initially should be false
        XCTAssertFalse(viewModel.canSubmitProgressive)
        
        // Only goal set
        viewModel.selectedGoal = .hypertrophy
        XCTAssertFalse(viewModel.canSubmitProgressive)
        
        // Goal and structure set
        viewModel.selectedStructure = .fullGym
        XCTAssertTrue(viewModel.canSubmitProgressive)
    }
    
    @MainActor
    func testCanSubmitFullRequiresAllFields() {
        // Initially should be false
        XCTAssertFalse(viewModel.canSubmitFull)
        
        // Set all required fields
        viewModel.selectedGoal = .hypertrophy
        viewModel.selectedStructure = .fullGym
        viewModel.selectedMethod = .traditional
        viewModel.selectedLevel = .intermediate
        viewModel.setFrequency(3)
        
        XCTAssertTrue(viewModel.canSubmitFull)
    }
    
    @MainActor
    func testApplyDefaultsSetsCorrectValues() {
        // Before applying defaults
        XCTAssertNil(viewModel.selectedLevel)
        XCTAssertNil(viewModel.selectedMethod)
        XCTAssertNil(viewModel.weeklyFrequency)
        XCTAssertTrue(viewModel.selectedConditions.isEmpty)
        
        // Apply defaults
        viewModel.applyDefaults()
        
        // Verify defaults are applied
        XCTAssertEqual(viewModel.selectedLevel, OnboardingFlowViewModel.defaultLevel)
        XCTAssertEqual(viewModel.selectedMethod, OnboardingFlowViewModel.defaultMethod)
        XCTAssertEqual(viewModel.weeklyFrequency, OnboardingFlowViewModel.defaultFrequency)
        XCTAssertEqual(viewModel.selectedConditions, Set(OnboardingFlowViewModel.defaultConditions))
    }
    
    @MainActor
    func testApplyDefaultsDoesNotOverwriteUserSelections() {
        // User selects values
        viewModel.selectedLevel = .advanced
        viewModel.selectedMethod = .hiit
        viewModel.setFrequency(5)
        viewModel.toggleCondition(.lowerBackPain)
        
        // Apply defaults
        viewModel.applyDefaults()
        
        // Verify user selections are preserved
        XCTAssertEqual(viewModel.selectedLevel, .advanced)
        XCTAssertEqual(viewModel.selectedMethod, .hiit)
        XCTAssertEqual(viewModel.weeklyFrequency, 5)
        XCTAssertTrue(viewModel.selectedConditions.contains(.lowerBackPain))
    }
    
    @MainActor
    func testSubmitProgressiveProfileSucceeds() async {
        // Setup
        viewModel.selectedGoal = .weightLoss
        viewModel.selectedStructure = .bodyweight
        
        // Submit
        let success = await viewModel.submitProgressiveProfile()
        
        // Verify
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.isProfileIncomplete)
        XCTAssertNotNil(mockRepository.savedProfile)
        XCTAssertEqual(mockRepository.savedProfile?.mainGoal, .weightLoss)
        XCTAssertEqual(mockRepository.savedProfile?.availableStructure, .bodyweight)
        XCTAssertFalse(mockRepository.savedProfile?.isProfileComplete ?? true)
        
        // Verify defaults were applied
        XCTAssertEqual(mockRepository.savedProfile?.level, OnboardingFlowViewModel.defaultLevel)
        XCTAssertEqual(mockRepository.savedProfile?.preferredMethod, OnboardingFlowViewModel.defaultMethod)
        XCTAssertEqual(mockRepository.savedProfile?.weeklyFrequency, OnboardingFlowViewModel.defaultFrequency)
    }
    
    @MainActor
    func testSubmitProgressiveProfileFailsWithoutRequiredFields() async {
        // No fields set
        let success = await viewModel.submitProgressiveProfile()
        
        // Verify
        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(mockRepository.savedProfile)
    }
    
    @MainActor
    func testSubmitFullProfileSucceeds() async {
        // Setup all fields
        viewModel.selectedGoal = .performance
        viewModel.selectedStructure = .fullGym
        viewModel.selectedMethod = .circuit
        viewModel.selectedLevel = .advanced
        viewModel.setFrequency(5)
        viewModel.toggleCondition(.shoulder)
        
        // Submit
        let success = await viewModel.submitFullProfile()
        
        // Verify
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isProfileIncomplete)
        XCTAssertNotNil(mockRepository.savedProfile)
        XCTAssertTrue(mockRepository.savedProfile?.isProfileComplete ?? false)
        XCTAssertEqual(mockRepository.savedProfile?.mainGoal, .performance)
        XCTAssertEqual(mockRepository.savedProfile?.level, .advanced)
        XCTAssertEqual(mockRepository.savedProfile?.weeklyFrequency, 5)
    }
    
    @MainActor
    func testSubmitFullProfileFailsWithMissingFields() async {
        // Only partial fields
        viewModel.selectedGoal = .hypertrophy
        viewModel.selectedStructure = .fullGym
        // Missing: method, level, frequency
        
        let success = await viewModel.submitFullProfile()
        
        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Health Conditions Toggle Tests
    
    @MainActor
    func testToggleConditionNoneClearsOthers() {
        // Add some conditions
        viewModel.toggleCondition(.lowerBackPain)
        viewModel.toggleCondition(.knee)
        XCTAssertEqual(viewModel.selectedConditions.count, 2)
        
        // Toggle "none" should clear others
        viewModel.toggleCondition(.none)
        XCTAssertEqual(viewModel.selectedConditions, [.none])
    }
    
    @MainActor
    func testToggleConditionRemovesNone() {
        // Start with none
        viewModel.toggleCondition(.none)
        XCTAssertEqual(viewModel.selectedConditions, [.none])
        
        // Adding another condition should remove "none"
        viewModel.toggleCondition(.shoulder)
        XCTAssertFalse(viewModel.selectedConditions.contains(.none))
        XCTAssertTrue(viewModel.selectedConditions.contains(.shoulder))
    }
    
    @MainActor
    func testToggleConditionTogglesOnOff() {
        // Add condition
        viewModel.toggleCondition(.knee)
        XCTAssertTrue(viewModel.selectedConditions.contains(.knee))
        
        // Remove condition
        viewModel.toggleCondition(.knee)
        XCTAssertFalse(viewModel.selectedConditions.contains(.knee))
    }
    
    // MARK: - Default Values Tests
    
    @MainActor
    func testDefaultValuesAreCorrect() {
        XCTAssertEqual(OnboardingFlowViewModel.defaultLevel, .intermediate)
        XCTAssertEqual(OnboardingFlowViewModel.defaultMethod, .mixed)
        XCTAssertEqual(OnboardingFlowViewModel.defaultFrequency, 3)
        XCTAssertEqual(OnboardingFlowViewModel.defaultConditions, [.none])
    }
}

// MARK: - Mock Repository (prefixed to avoid conflicts)

class MockOUserProfileRepository: UserProfileRepository {
    var savedProfile: UserProfile?
    var shouldThrowError = false
    
    func loadProfile() async throws -> UserProfile? {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        return savedProfile
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        savedProfile = profile
    }
}

