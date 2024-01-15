import UIKit
import FirebaseCore
import FirebaseMessaging
import FBSDKCoreKit
import AirBridge
import AdSupport
import UserNotifications
import SDWebImage
import SDWebImageWebPCoder

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setupApplication(application, launchOptions)
        return true
    }
    
    private func setupApplication(_ application: UIApplication, _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // UNUserNotificationCenter 델리게이트 설정
        
        // AirBridge 초기화
        AirBridge.getInstance("ce116649821f4c9fab702a34765735b2", appName: "delgo", withLaunchOptions: launchOptions)
        
        // 광고 식별자 설정
        let sharedASIdentifierManager = ASIdentifierManager.shared()
        let adID = sharedASIdentifierManager.advertisingIdentifier
        
        // 푸시 권한 요청
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    UNUserNotificationCenter.current().delegate = self
                }
            }
        )
        // 푸시 등록
        application.registerForRemoteNotifications()

        // SDWebImageWebPCoder 초기화
        let WebPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(WebPCoder)
    }

  
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // FCM 토큰 설정
        self.setUpFirebaseMessaging()
    }
  
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 푸시 등록 실패 처리
        print(#function, error)
    }
      
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Facebook 앱 이벤트 활성화
        FBSDKAppEvents.activateApp()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // AirBridge 딥링크 처리
        AirBridge.deeplink()?.handleURLSchemeDeeplink(url)
        FBSDKApplicationDelegate.sharedInstance().application(app, open: url)
        return true
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // AirBridge 사용자 액티비티 처리
        AirBridge.deeplink()?.handle(userActivity)
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

// MARK: UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // 앱이 실행 중일 때 푸시 알림 처리 옵션 설정
        return [[.badge, .banner, .list, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        딥링크로리다이렉트(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func 딥링크로리다이렉트(_ noti: [AnyHashable: Any]) {
        guard let urlData = noti["custom"] as? [String: Any] else { return }
        if let imageURL = urlData["imageUrl"] as? String, let url = urlData["url"] as? String {
            guard let url = URL(string: url) else { return }
            NotificationCenter.default.post(name: Notification.Name("deeplink"), object: url)
        }
    }
}

// MARK: MessagingDelegate
extension AppDelegate: MessagingDelegate {
    
    private func setUpFirebaseMessaging() {
        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self
        
        // FCM 토큰 요청
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
    }
    
    /// FCM 토큰 갱신 시 호출되는 메서드
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // FCM 토큰을 사용하여 원하는 작업 수행
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        
        // FCM 토큰을 NotificationCenter로 전달
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
