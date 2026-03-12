//
//  SocialFeedViewModelTests.swift
//  FitTodayTests
//
//  Created by Claude on 12/03/26.
//

import XCTest
@testable import FitToday

@MainActor
final class SocialFeedViewModelTests: XCTestCase {

    private var sut: SocialFeedViewModel!
    private var mockFeedRepo: MockFeedRepository!
    private var mockAuthRepo: MockAuthenticationRepository!
    private var mockDeleteUseCase: DeleteFeedPostUseCase!

    override func setUp() {
        super.setUp()
        mockFeedRepo = MockFeedRepository()
        mockAuthRepo = MockAuthenticationRepository()
        mockDeleteUseCase = DeleteFeedPostUseCase(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo
        )
        sut = SocialFeedViewModel(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo,
            deleteFeedPostUseCase: mockDeleteUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockFeedRepo = nil
        mockAuthRepo = nil
        super.tearDown()
    }

    // MARK: - Load Feed

    func test_loadFeed_whenAuthenticated_loadsPosts() async {
        // Given
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        mockFeedRepo.postsToReturn = [.fixture(id: "post-1"), .fixture(id: "post-2")]

        // When
        await sut.loadFeed()

        // Then
        XCTAssertEqual(sut.posts.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadFeed_whenNotAuthenticated_setsError() async {
        // Given
        mockAuthRepo.currentUserResult = nil

        // When
        await sut.loadFeed()

        // Then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadFeed_whenNotInGroup_setsError() async {
        // Given
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: nil)

        // When
        await sut.loadFeed()

        // Then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Toggle Like

    func test_toggleLike_updatesPostLocally() async {
        // Given
        let post = FeedPost.fixture(id: "post-1", likedBy: [])
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        mockFeedRepo.postsToReturn = [post]
        mockFeedRepo.toggleLikeResult = true
        await sut.loadFeed()

        // When
        await sut.toggleLike(postId: "post-1")

        // Then
        XCTAssertEqual(sut.posts.first?.likeCount, 1)
        XCTAssertTrue(sut.posts.first?.likedBy.contains("user-1") ?? false)
    }

    // MARK: - Delete Post

    func test_deletePost_removesFromList() async {
        // Given
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        mockFeedRepo.postsToReturn = [.fixture(id: "post-1"), .fixture(id: "post-2")]
        await sut.loadFeed()
        XCTAssertEqual(sut.posts.count, 2)

        // When
        await sut.deletePost("post-1")

        // Then
        XCTAssertEqual(sut.posts.count, 1)
        XCTAssertEqual(sut.posts.first?.id, "post-2")
    }

    // MARK: - Is Current User

    func test_isCurrentUser_returnsCorrectly() async {
        // Given
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        await sut.loadFeed()

        // Then
        XCTAssertTrue(sut.isCurrentUser("user-1"))
        XCTAssertFalse(sut.isCurrentUser("user-2"))
    }

    // MARK: - Is Post Liked

    func test_isPostLiked_checksCurrentUser() async {
        // Given
        let likedPost = FeedPost.fixture(id: "p1", likedBy: ["user-1"])
        let unlikedPost = FeedPost.fixture(id: "p2", likedBy: ["user-2"])
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        mockFeedRepo.postsToReturn = [likedPost, unlikedPost]
        await sut.loadFeed()

        // Then
        XCTAssertTrue(sut.isPostLiked(likedPost))
        XCTAssertFalse(sut.isPostLiked(unlikedPost))
    }
}

// MARK: - Create Post ViewModel Tests

@MainActor
final class CreatePostViewModelTests: XCTestCase {

    func test_submitPost_createsPostSuccessfully() async {
        // Given
        let mockFeedRepo = MockFeedRepository()
        let mockAuthRepo = MockAuthenticationRepository()
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")
        mockFeedRepo.createPostResult = .fixture(id: "new-post")

        let compressor = MockImageCompressor()
        let useCase = CreateFeedPostUseCase(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo,
            imageCompressor: compressor
        )

        let sut = CreatePostViewModel(
            createPostUseCase: useCase,
            workoutTitle: "Treino Full Body",
            workoutDurationMinutes: 45,
            exerciseCount: 8,
            totalVolume: 2500
        )

        // Simulate selecting an image (1x1 red pixel)
        sut.selectedImage = UIImage.testImage()

        // When
        await sut.submitPost()

        // Then
        XCTAssertNotNil(sut.createdPost)
        XCTAssertFalse(sut.isSubmitting)
        XCTAssertNil(sut.errorMessage)
    }

    func test_canSubmit_requiresImage() {
        let mockFeedRepo = MockFeedRepository()
        let mockAuthRepo = MockAuthenticationRepository()
        let compressor = MockImageCompressor()
        let useCase = CreateFeedPostUseCase(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo,
            imageCompressor: compressor
        )

        let sut = CreatePostViewModel(
            createPostUseCase: useCase,
            workoutTitle: "Treino",
            workoutDurationMinutes: 30,
            exerciseCount: 5,
            totalVolume: nil
        )

        // No image selected
        XCTAssertFalse(sut.canSubmit)

        // With image
        sut.selectedImage = UIImage.testImage()
        XCTAssertTrue(sut.canSubmit)
    }
}

// MARK: - Comments ViewModel Tests

@MainActor
final class FeedCommentsViewModelTests: XCTestCase {

    func test_addComment_clearsText() async {
        // Given
        let mockFeedRepo = MockFeedRepository()
        let mockAuthRepo = MockAuthenticationRepository()
        mockAuthRepo.currentUserResult = SocialUser.testUser(groupId: "group-1")

        let sut = FeedCommentsViewModel(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo,
            postId: "post-1"
        )
        sut.commentText = "Ótimo treino!"

        // When
        await sut.addComment()

        // Then
        XCTAssertTrue(sut.commentText.isEmpty)
        XCTAssertTrue(mockFeedRepo.addCommentCalled)
    }

    func test_canSubmit_requiresNonEmptyText() {
        let mockFeedRepo = MockFeedRepository()
        let mockAuthRepo = MockAuthenticationRepository()
        let sut = FeedCommentsViewModel(
            feedRepository: mockFeedRepo,
            authRepository: mockAuthRepo,
            postId: "post-1"
        )

        XCTAssertFalse(sut.canSubmit)

        sut.commentText = "   "
        XCTAssertFalse(sut.canSubmit)

        sut.commentText = "Nice!"
        XCTAssertTrue(sut.canSubmit)
    }
}

// MARK: - Test Doubles

final class MockFeedRepository: FeedRepository, @unchecked Sendable {
    var postsToReturn: [FeedPost] = []
    var createPostResult: FeedPost?
    var toggleLikeResult: Bool = true
    var addCommentCalled = false
    var deletePostCalled = false

    func createPost(_ post: FeedPost, mediaData: Data?) async throws -> FeedPost {
        createPostResult ?? post
    }

    func deletePost(_ postId: String, authorId: String) async throws {
        deletePostCalled = true
    }

    func getPosts(groupId: String, limit: Int, after: Date?) async throws -> [FeedPost] {
        postsToReturn
    }

    func observePosts(groupId: String) -> AsyncStream<[FeedPost]> {
        AsyncStream { continuation in
            continuation.yield(postsToReturn)
            continuation.finish()
        }
    }

    func toggleLike(postId: String, userId: String) async throws -> Bool {
        toggleLikeResult
    }

    func addComment(_ comment: FeedComment) async throws {
        addCommentCalled = true
    }

    func getComments(postId: String, limit: Int) async throws -> [FeedComment] {
        []
    }

    func observeComments(postId: String) -> AsyncStream<[FeedComment]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }
}

// MARK: - Test Fixtures

extension FeedPost {
    static func fixture(
        id: String = "post-1",
        authorId: String = "user-1",
        likedBy: [String] = []
    ) -> FeedPost {
        FeedPost(
            id: id,
            authorId: authorId,
            authorName: "Test User",
            workoutTitle: "Treino Full Body",
            workoutDurationMinutes: 45,
            exerciseCount: 8,
            likeCount: likedBy.count,
            likedBy: likedBy,
            groupId: "group-1"
        )
    }
}

extension SocialUser {
    static func testUser(groupId: String? = "group-1") -> SocialUser {
        SocialUser(
            id: "user-1",
            displayName: "Test User",
            email: "test@example.com",
            authProvider: .email,
            currentGroupId: groupId,
            privacySettings: PrivacySettings(),
            createdAt: Date()
        )
    }
}

extension UIImage {
    static func testImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
