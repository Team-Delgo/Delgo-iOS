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
        // Firebase 초기화
        FirebaseApp.configure()
        
        // UNUserNotificationCenter 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // AirBridge 초기화
        AirBridge.getInstance("ce116649821f4c9fab702a34765735b2", appName: "delgo", withLaunchOptions: launchOptions)
        
        // 광고 식별자 설정
        let sharedASIdentifierManager = ASIdentifierManager.shared()
        let adID = sharedASIdentifierManager.advertisingIdentifier
        
        // 푸시 권한 요청
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        // 푸시 등록
        application.registerForRemoteNotifications()

        // SDWebImageWebPCoder 초기화
        let WebPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(WebPCoder)
        
        return true
    }

  
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // FCM 토큰 설정
        self.setUpFirebaseMessaging()
    }
  
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 푸시 등록 실패 처리
        print(error)
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

// MARK: Notification Service Extension
import UserNotifications
import SDWebImage
import SDWebImageWebPCoder

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        // 알림 콘텐츠 핸들러 설정
        self.contentHandler = contentHandler
        // 복사된 알림 콘텐츠 가져오기
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            return
        }

        // 이미지 URL 추출 및 처리
        if let imageUrlString = bestAttemptContent.userInfo["imageURL"] as? String,
           let imageUrl = URL(string: imageUrlString) {
            // 이미지가 WebP 형식인 경우
            if imageUrl.pathExtension.lowercased() == "webp" {
                // SDWebImage를 사용하여 WebP 이미지 처리
                handleWebPImage(imageUrl, forContent: bestAttemptContent)
            } else {
                // 일반 이미지 처리
                downloadImageAndReplaceContent(imageUrl, forContent: bestAttemptContent)
            }
        }
    }

    func handleWebPImage(_ imageUrl: URL, forContent content: UNMutableNotificationContent) {
        // SDWebImage를 사용하여 WebP 이미지 다운로드 및 처리
        SDWebImageManager.shared.loadImage(with: imageUrl, options: [], progress: nil) { (image, data, error, _, _, _) in
            if let image = image,
               let attachment = self.createNotificationAttachment(image: image) {
                content.attachments = [attachment]
            }
            self.contentHandler?(content)
        }
    }

    func downloadImageAndReplaceContent(_ imageUrl: URL, forContent content: UNMutableNotificationContent) {
        // URLSession을 사용하여 이미지 다운로드
        downloadImage(from: imageUrl) { image in
            if let image = image,
               let attachment = self.createNotificationAttachment(image: image) {
                content.attachments = [attachment]
            }
            self.contentHandler?(content)
        }
    }

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // URLSession을 이용한 비동기 이미지 다운로드
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    func createNotificationAttachment(image: UIImage) -> UNNotificationAttachment? {
        // 이미지 파일을 임시 디렉터리에 저장하고 UNNotificationAttachment 생성
        let fileManager = FileManager.default
        let tempDirectory = NSTemporaryDirectory()
        let fileName = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
        let fileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)

        do {
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                try imageData.write(to: fileURL)
                let attachment = try UNNotificationAttachment(identifier: "", url: fileURL, options: nil)
                return attachment
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // 시간 제한 종료 전 콘텐츠 핸들러 호출
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
