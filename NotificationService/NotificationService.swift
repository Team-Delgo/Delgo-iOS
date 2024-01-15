//
//  NotificationService.swift
//  Delgo
//
//  Created by 델고 on 1/15/24.
//

import Foundation
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

