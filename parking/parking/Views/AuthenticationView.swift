import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Parking App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Find or rent parking spots near you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                Spacer()
                
                // Authentication Form
                if isSignUp {
                    SignUpView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else {
                    SignInView()
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                }
                
                Spacer()
                
                // Toggle between sign in and sign up
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                    }
                }) {
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .overlay(
                // Loading overlay
                Group {
                    if firebaseService.isLoading {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Please wait...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
            )
            .overlay(
                // Error message overlay
                Group {
                    if let errorMessage = firebaseService.errorMessage {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("Dismiss") {
                                    firebaseService.errorMessage = nil
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 8)
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .transition(.move(edge: .top))
                        .animation(.spring(), value: firebaseService.errorMessage)
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome Back")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Sign In button
            Button(action: {
                Task {
                    do {
                        try await firebaseService.signIn(email: email, password: password)
                    } catch {
                        // Error is handled by the service
                    }
                }
            }) {
                HStack {
                    if firebaseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                    
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || firebaseService.isLoading)
            
            // Forgot password
            Button("Forgot Password?") {
                // TODO: Implement forgot password
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your full name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Confirm Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm your password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm your password", text: $confirmPassword)
                        }
                        
                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Password validation
                if !password.isEmpty && password.count < 6 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            // Sign Up button
            Button(action: {
                Task {
                    do {
                        try await firebaseService.signUp(email: email, password: password, name: name)
                    } catch {
                        // Error is handled by the service
                    }
                }
            }) {
                HStack {
                    if firebaseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || firebaseService.isLoading)
            
            // Terms and conditions
            Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(FirebaseService())
}
