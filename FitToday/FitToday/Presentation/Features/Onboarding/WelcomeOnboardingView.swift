//
//  WelcomeOnboardingView.swift
//  FitToday
//
//  First-launch welcome onboarding with 4 pages.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    @AppStorage(AppStorageKeys.hasSeenWelcome) private var hasSeenWelcome = false
    @State private var currentPage = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "figure.strengthtraining.traditional",
            title: "welcome.page1.title",
            description: "welcome.page1.description"
        ),
        WelcomePage(
            icon: "list.bullet.clipboard",
            title: "welcome.page2.title",
            description: "welcome.page2.description"
        ),
        WelcomePage(
            icon: "sparkles",
            title: "welcome.page3.title",
            description: "welcome.page3.description"
        ),
        WelcomePage(
            icon: "flame.fill",
            title: "welcome.page4.title",
            description: "welcome.page4.description"
        ),
    ]

    var body: some View {
        ZStack {
            FitTodayColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: FitTodaySpacing.md) {
                    Button {
                        if currentPage == pages.count - 1 {
                            hasSeenWelcome = true
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1
                             ? "welcome.getStarted".localized
                             : "welcome.continue".localized)
                            .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FitTodayColor.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    }
                    .buttonStyle(.plain)

                    if currentPage < pages.count - 1 {
                        Button {
                            hasSeenWelcome = true
                        } label: {
                            Text("welcome.skip".localized)
                                .font(FitTodayFont.ui(size: 14, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, FitTodaySpacing.lg)
                .padding(.bottom, FitTodaySpacing.xl)
            }
        }
    }

    private func pageView(_ page: WelcomePage) -> some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .shadow(color: FitTodayColor.brandPrimary.opacity(0.4), radius: 20)

            Text(page.title.localized)
                .font(FitTodayFont.ui(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.description.localized)
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FitTodaySpacing.xl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FitTodaySpacing.lg)
    }
}

private struct WelcomePage {
    let icon: String
    let title: String
    let description: String
}
