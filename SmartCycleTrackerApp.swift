import SwiftUI
import LocalAuthentication

@main
struct SmartCycleTrackerApp: App {
    @State private var isUnlocked: Bool = false
    @State private var isPrivacyLockEnabled: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isPrivacyLockEnabled && !isUnlocked {
                    // 隐私解锁页面
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.periodRuby)
                        
                        Text("SmartCycleTracker 隐私锁")
                            .font(.system(size: 20, weight: .bold))

                        Text("经期数据已进行本地端侧安全加密保护")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: "faceid")
                                Text("使用 Face ID / Touch ID 解锁")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Theme.periodRuby)
                            .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.backgroundGradient.ignoresSafeArea())
                } else {
                    MainTabView()
                }
            }
            .onAppear {
                // 如果开启了隐私锁，则触发生物识别解锁
                if isPrivacyLockEnabled {
                    authenticateWithBiometrics()
                }
            }
        }
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "请解锁以访问您的隐私经期健康记录"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            // 设备不支持生物识别时直接进入（或输入系统密码）
            self.isUnlocked = true
        }
    }
}
