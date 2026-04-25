import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // — Logo + wordmark header —
                    HStack(spacing: 10) {
                        Image("AppUtilityIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Savely")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 28)

                    // — Welcome heading —
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome\nback.")
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                            .lineSpacing(2)
                        Text("Your goals are waiting.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.warmInkMuted)
                    }
                    .padding(.bottom, 32)

                    // — Fields —
                    VStack(spacing: 14) {
                        WarmField(label: "EMAIL", value: $viewModel.email, placeholder: "you@example.com", keyboard: .emailAddress, secure: false)
                        WarmField(label: "PASSWORD", value: $viewModel.password, placeholder: "••••••••••", keyboard: .default, secure: true)

                        HStack {
                            Spacer()
                            Button("Forgot password?") {}
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.warmGreen)
                        }
                        .padding(.top, -4)
                    }
                    .padding(.bottom, 22)

                    // — Sign in —
                    Button(action: {
                        Task {
                            do { try await viewModel.signIn() }
                            catch { print(error) }
                        }
                    }) {
                        Text(Strings.Authentication.signInString)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.warmGreen)
                            .cornerRadius(14)
                    }
                    .padding(.bottom, 24)

                    // — OR —
                    HStack(spacing: 12) {
                        Rectangle().fill(Color.warmLine).frame(height: 1)
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.warmInkMuted)
                            .padding(.horizontal, 4)
                        Rectangle().fill(Color.warmLine).frame(height: 1)
                    }
                    .padding(.bottom, 24)

                    // — Apple sign in —
                    Button(action: {
                        Task {
                            do { try await viewModel.signInApple() }
                            catch { print(error) }
                        }
                    }) {
                        SignInWithAppleButtonViewRepresentable(type: .signIn, style: colorScheme == .dark ? .white : .black)
                            .allowsHitTesting(false)
                    }
                    .frame(height: 50)
                    .cornerRadius(14)
                    .padding(.bottom, 32)

                    // — Sign up —
                    HStack {
                        Spacer()
                        Text(Strings.Authentication.dontHaveAccount)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.warmInkMuted)
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text(Strings.Authentication.signUpLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.warmGreen)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 28)
            }
            .background(Color.warmBg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Warm text field

struct WarmField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    let keyboard: UIKeyboardType
    let secure: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
            Group {
                if secure {
                    SecureField(placeholder, text: $value)
                } else {
                    TextField(placeholder, text: $value)
                        .keyboardType(keyboard)
                        .autocapitalization(keyboard == .emailAddress ? .none : .sentences)
                }
            }
            .font(.system(size: 16))
            .foregroundStyle(Color.warmInk)
            .frame(height: 52)
            .padding(.horizontal, 16)
            .background(Color.warmSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmLine, lineWidth: 1))
        }
    }
}

#Preview { LoginView() }
