# Project: FitToday

## Quick Reference
- **Platform**: iOS 17+ / macOS 14+
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable
- **Minimum Deployment**: iOS 17.0
- **Package Manager**: Swift Package Manager

## XcodeBuildMCP Integration
**IMPORTANT**: This project uses XcodeBuildMCP for all Xcode operations.
- Build: `mcp__xcodebuildmcp__build_sim_name_proj`
- Test: `mcp__xcodebuildmcp__test_sim_name_proj`
- Clean: `mcp__xcodebuildmcp__clean`

## Project Structure

Data: Repository concrete implementation, DTOs, DataMappers, known-by Application Layer
Domain: Pure structs respecting business logic, Repository protocols to execute UseCases
Presentation: Features only, UI/Views, ViewModels, known-by Application Layer

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)

### SwiftUI Patterns
- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use SwiftInject for dependency injection
- Prefer `Router Navigation Pattern` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects

### Error Handling
// Always use typed errors
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case validationError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .validationError(let msg): return msg
        }
    }
}

### Testing Requirements
- Unit tests for all ViewModels
- Unit trst for layers of logic
- Prefer use spies, stubs, mocks and fixtures for simulate real data
- Use XCTest framework
- Minimum 70% code coverage for business logic

### DO NOT
- Write UITests during scaffolding phase
- Use deprecated APIs (UIKit when SwiftUI suffices)
- Create massive monolithic views
- Use force unwrapping (!) without justification
- Ignore Swift 6 concurrency warnings

After completing a task that involves tools use, provide a quick summary of the work you've done.

<investigate_before_answering>
Reduce hallucinations:
Never speculate about code you have not opened. If the user
references a specific file, you MUST read the file before
answering. Make sure to investigate and read relevant files BEFORE
answering questions about the codebase. Never make any claims about
code before investigating unless you are certain of the correct
answer - give grounded and hallucination-free answers.
</investigate_before_answering>