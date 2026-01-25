//
//  AuthenticationView.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import AuthenticationServices
import SwiftUI
import Swinject

struct AuthenticationView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthenticationViewModel?

    // Email/Password state
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var showEmailAuth = false

    // Context for deep link (e.g., group invitation)
    var inviteContext: String?

    // Callback when authentication succeeds
    var onAuthenticated: (() -> Void)?

    init(resolver: Resolver, inviteContext: String? = nil, onAuthenticated: (() -> Void)? = nil) {
        self.inviteContext = inviteContext
        self.onAuthenticated = onAuthenticated
        _viewModel = State(initialValue: AuthenticationViewModel(resolver: resolver))
    }

    var body: some View {
        ZStack {
            // Retro background with grid
            ZStack {
                FitTodayColor.background
                RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.2), spacing: 40)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: FitTodaySpacing.xl) {
                    Spacer()
                        .frame(height: 40)

                    // Logo and welcome
                    VStack(spacing: FitTodaySpacing.md) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(0.4))

                        Text("FIT TODAY")
                            .font(FitTodayFont.display(size: 32, weight: .extraBold))
                            .tracking(2.0)
                            .foregroundStyle(FitTodayColor.textPrimary)

                        if let context = inviteContext {
                            Text(context)
                                .font(FitTodayFont.ui(size: 16, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FitTodaySpacing.lg)
                        } else {
                            Text("ENTRE PARA ACESSAR GRUPOS")
                                .font(FitTodayFont.ui(size: 16, weight: .medium))
                                .tracking(0.5)
                                .foregroundStyle(FitTodayColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FitTodaySpacing.lg)
                        }
                    }

                    Spacer()
                        .frame(height: 20)

                    // Authentication options card
                    VStack(spacing: FitTodaySpacing.md) {
                        // Apple Sign-In
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                Task {
                                    await viewModel?.signInWithApple()
                                }
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await viewModel?.handleAppleSignInCompletion(result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(FitTodayRadius.sm)
                        .techCornerBorders(length: 14, thickness: 1.5)

                        // Google Sign-In (placeholder)
                        Button {
                            Task {
                                await viewModel?.signInWithGoogle()
                            }
                        } label: {
                            HStack(spacing: FitTodaySpacing.sm) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Continuar com Google")
                                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .cornerRadius(FitTodayRadius.sm)
                        .techCornerBorders(color: FitTodayColor.textTertiary, length: 14, thickness: 1.5)

                        // Email/Password toggle
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showEmailAuth.toggle()
                            }
                        } label: {
                            HStack(spacing: FitTodaySpacing.sm) {
                                Image(systemName: showEmailAuth ? "envelope.open.fill" : "envelope.fill")
                                    .font(.title3)
                                Text("Continuar com Email")
                                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                                    .tracking(0.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(FitTodayColor.surface)
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .cornerRadius(FitTodayRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                .stroke(FitTodayColor.outline, lineWidth: 1)
                        )
                        .techCornerBorders(color: FitTodayColor.techBorder, length: 14, thickness: 1.5)
                    }
                    .padding(.horizontal, FitTodaySpacing.lg)

                    // Email/Password form
                    if showEmailAuth {
                        VStack(spacing: FitTodaySpacing.md) {
                            if isSignUp {
                                TextField("", text: $displayName, prompt: Text("Nome completo").foregroundStyle(FitTodayColor.textTertiary))
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .font(FitTodayFont.ui(size: 17, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                    .padding()
                                    .background(FitTodayColor.surface)
                                    .cornerRadius(FitTodayRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                            .stroke(FitTodayColor.outline, lineWidth: 1)
                                    )
                            }

                            TextField("", text: $email, prompt: Text("Email").foregroundStyle(FitTodayColor.textTertiary))
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .font(FitTodayFont.ui(size: 17, weight: .medium))
                                .foregroundStyle(FitTodayColor.textPrimary)
                                .padding()
                                .background(FitTodayColor.surface)
                                .cornerRadius(FitTodayRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                        .stroke(FitTodayColor.outline, lineWidth: 1)
                                )

                            SecureField("", text: $password, prompt: Text("Senha").foregroundStyle(FitTodayColor.textTertiary))
                                .textContentType(isSignUp ? .newPassword : .password)
                                .font(FitTodayFont.ui(size: 17, weight: .medium))
                                .foregroundStyle(FitTodayColor.textPrimary)
                                .padding()
                                .background(FitTodayColor.surface)
                                .cornerRadius(FitTodayRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                                        .stroke(FitTodayColor.outline, lineWidth: 1)
                                )

                            Button {
                                Task {
                                    if isSignUp {
                                        await viewModel?.createAccount(
                                            email: email,
                                            password: password,
                                            displayName: displayName
                                        )
                                    } else {
                                        await viewModel?.signInWithEmail(email, password: password)
                                    }
                                }
                            } label: {
                                Text(isSignUp ? "Criar conta" : "Entrar")
                            }
                            .fitPrimaryStyle()
                            .padding(.top, FitTodaySpacing.sm)

                            Button {
                                withAnimation {
                                    isSignUp.toggle()
                                }
                            } label: {
                                Text(isSignUp ? "Já tem uma conta? Entrar" : "Não tem conta? Criar")
                                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                                    .foregroundStyle(FitTodayColor.brandPrimary)
                            }
                        }
                        .padding(.horizontal, FitTodaySpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()
                        .frame(height: 40)
                }
            }
            .scrollIndicators(.hidden)

            // Loading overlay with retro style
            if viewModel?.isLoading == true {
                ZStack {
                    FitTodayColor.background.opacity(0.9)
                        .ignoresSafeArea()

                    VStack(spacing: FitTodaySpacing.md) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(FitTodayColor.brandPrimary)
                            .scaleEffect(1.5)

                        Text("AUTENTICANDO...")
                            .font(FitTodayFont.ui(size: 14, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                    .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(0.3))
                }
            }
        }
        .alert(
            viewModel?.errorMessage?.title ?? "Erro",
            isPresented: Binding(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel?.errorMessage = nil
            }
        } message: {
            if let message = viewModel?.errorMessage?.message {
                Text(message)
            }
        }
        .onChange(of: viewModel?.didAuthenticate) { _, didAuthenticate in
            if didAuthenticate == true {
                #if DEBUG
                print("[Auth] ✅ Authentication succeeded, dismissing view")
                #endif
                onAuthenticated?()
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView(resolver: AppContainer.build().container)
}
