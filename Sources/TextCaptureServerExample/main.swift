//
//  main.swift
//  TextCaptureServerExample
//
//  Created by Pepe Becker on 2023/02/06.
//

import Foundation
import TextCaptureServer

let semaphore = DispatchSemaphore(value: 0)
do {
  let port = 4444
  let serverUrl = "http://localhost:\(port)"
  let clientUrl = URL(string: "https://textcapture.surge.sh")!
  var components = URLComponents(url: clientUrl, resolvingAgainstBaseURL: false)!
  components.queryItems = [URLQueryItem(name: "server", value: serverUrl)]
  let server = TextCaptureServer(clientUrl: components.url!)
  try server.start(port: port)
  print("Running at \(serverUrl)")
  semaphore.wait()
} catch {
  semaphore.signal()
  print("Error: \(error.localizedDescription)")
}
