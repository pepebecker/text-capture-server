//
//  Utils.swift
//  TextCapture
//
//  Created by Pepe Becker on 2023/01/30.
//

import Foundation

struct Utils {
  static func languageName(for code: String) -> String {
    if code == "zh-CN" || code == "zh-Hans" {
      return "中文(简体)"
    }
    if code == "zh-TW" || code == "zh-Hant" {
      return "中文(繁體)"
    }
    let locale = Locale(identifier: code)
    if let languageName = locale.localizedString(forLanguageCode: code) {
      return languageName.capitalized
    } else {
      return code
    }
  }
}
