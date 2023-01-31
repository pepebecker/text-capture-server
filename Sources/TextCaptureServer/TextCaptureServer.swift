//
//  TextCaptureServer.swift
//  TextCaptureServer
//
//  Created by Pepe Becker on 2023/02/05.
//

import AppKit
import Kitura
import KituraCORS
import TextRecognizer
import Papago

public class TextCaptureServer {

  public let router = Router()
  public let papago = Papago()

  internal let cors: CORS
  internal let clientUrl: URL?
  internal let getClientHtml: (() -> String?)?

  public init(clientUrl: URL) {
    let options = Options(allowedOrigin: .all)
    self.cors = CORS(options: options)
    self.clientUrl = clientUrl
    self.getClientHtml = nil
    setupRoutes()
  }

  public init(clientHtmlProvider: @escaping () -> String?) {
    let options = Options(allowedOrigin: .all)
    self.cors = CORS(options: options)
    self.clientUrl = nil
    self.getClientHtml = clientHtmlProvider
    setupRoutes()
  }

  public convenience init(clientHtmlPath: String) {
    self.init(clientHtmlProvider: { try? String(contentsOfFile: clientHtmlPath) })
  }

  public convenience init() {
    if let clientPath = ProcessInfo.processInfo.environment["TEXT_CAPTURE_CLIENT_PATH"] {
      self.init(clientHtmlPath: clientPath)
    } else {
      self.init(clientHtmlProvider: { nil })
    }
  }

  internal func createLanguageEntry(code: String) -> [String: String] {
    return ["name": Utils.languageName(for: code), "code": code]
  }

  public func getRecognitionLanguages() throws -> [[String: String]] {
    return try TextRecognizer.supportedLanguages().map { lang in
      return createLanguageEntry(code: lang)
    }
  }

  public func getTranslationLanguages(for source: String) -> [[String: String]] {
    return Papago.targetLanguagues(for: source).map { target in
      return createLanguageEntry(code: target.rawValue)
    }
  }

  internal func jsonToUInt8Array(_ json: Any) throws -> [UInt8]? {
    let data = try JSONSerialization.data(withJSONObject: json, options: [])
    return [UInt8](data)
  }

  internal func createImageRequestHandler() -> RouterHandler {
    return { req, res, next in
      guard let body = req.body?.asJSON as? [String: String] else {
        fputs("Could not parse body\n", stderr)
        res.status(.badRequest).send("Could not parse body")
        next()
        return
      }
      let lang = body["lang"] ?? "en"
      guard let base64Image = body["image"] else {
        fputs("Could not find base64 image\n", stderr)
        res.status(.badRequest).send("Could not find base64 image")
        next()
        return
      }
      let base64Data = base64Image.replacingOccurrences(of: "^data:image/\\w+;base64,", with: "", options: .regularExpression)
      let imagePath = "\(NSTemporaryDirectory())image.png"
      guard let data = Data(base64Encoded: base64Data) else {
        fputs("Could not decode base64 image\n", stderr)
        res.status(.badRequest).send("Could not decode base64 image")
        next()
        return
      }
      do {
        try data.write(to: URL(fileURLWithPath: imagePath))
      } catch {
        fputs("Could not write image to disk\n", stderr)
        res.status(.internalServerError).send("Could not write image to disk")
        next()
        return
      }
      guard let image = NSImage(contentsOfFile: imagePath) else {
        fputs("Could not load image\n", stderr)
        res.status(.internalServerError).send("Could not load image")
        next()
        return
      }
      if let results = try? TextRecognizer.recognize(image: image, languages: [lang]) {
        res.send(json: results)
        next()
        return
      } else {
        fputs("Could not recognize text\n", stderr)
        res.status(.internalServerError).send("Could not recognize text")
        next()
        return
      }
    }
  }

  internal func createTranslateRequestHandler() -> RouterHandler {
    return { req, res, next in
      guard let body = req.body?.asJSON as? [String: String] else {
        fputs("Could not parse body\n", stderr)
        res.status(.badRequest).send("Could not parse body")
        next()
        return
      }
      let source = body["source"] ?? "auto"
      let target = body["target"] ?? "en"
      let text = body["text"] ?? ""
      if text.isEmpty {
        fputs("No text to translate\n", stderr)
        res.status(.badRequest).send("No text to translate")
        next()
        return
      }
      var result: String?
      var error: Error?
      let semaphore = DispatchSemaphore(value: 0)
      self.papago.translate(text: text, from: source, to: target, honorific: nil) { (res, err) in
        result = res
        error = err
        semaphore.signal()
      }
      semaphore.wait()
      if let error = error {
        fputs("\(error.localizedDescription)\n", stderr)
        res.status(.internalServerError).send(error.localizedDescription)
        next()
        return
      }
      guard let result = result else {
        fputs("No result\n", stderr)
        res.status(.noContent).send("No result")
        next()
        return
      }
      res.send(result)
      next()
      return
    }
  }

  internal func setupRoutes() {
    router.all(middleware: cors)
    router.all(middleware: BodyParser())
    router.get("/") { req, res, next in
      if let provider = self.getClientHtml, let html = provider() {
        res.send(html)
      } else if let url = self.clientUrl {
        try res.redirect(url.absoluteString, status: .movedPermanently)
      } else {
        res.send("Could not get client")
      }
      next()
    }
    router.get("/source-languages") { req, res, next in
      if let languages = try? self.getRecognitionLanguages() {
        res.send(languages)
      } else {
        res.send("Could not get recognition languages")
      }
      next()
    }
    router.get("/target-languages") { req, res, next in
      if let source = req.queryParameters["source"] {
        res.send(json: self.getTranslationLanguages(for: source))
      } else {
        res.send(json: self.getTranslationLanguages(for: "en"))
      }
      next()
    }
    router.post("/image", handler: createImageRequestHandler())
    router.post("/translate", handler: createTranslateRequestHandler())
  }

  public func start(port: Int) throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    let failedStarts = Kitura.startWithStatus()
    if failedStarts > 0 {
      throw NSError(domain: "TextCaptureServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not start server"])
    }
  }

  public func stop() {
    Kitura.stop()
  }

}
