//
//  FCMToken.swift
//  Delgo
//
//  Created by Woochan Park on 2022/12/18.
//

import Foundation

struct FCMToken: Encodable {
  
  var userId: Int
  
  var fcmToken: String
}
