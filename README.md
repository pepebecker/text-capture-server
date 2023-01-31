# Text Capture Server
A swift package for a text capture server that supports image recognition and translation.

# Installation
Use the Swift Package Manager to install the package.

Add the following dependency to your Package.swift file:

```swift
.package(url: "https://github.com/pepebecker/text-capture-server.git", from: "0.1.0")
```

# Usage
The package provides gour initializer methods for creating an instance of the TextCaptureServer class:

- `init(clientUrl: URL)`: initializes the server with the client UI hosted at the given URL.
- `init(clientHtmlProvider: @escaping () -> String?)`: initializes the server with the client UI provided by the given closure.
- `init(clientHtmlPath: String)`: initializes the server with the client UI located at the given file path.
- `init()`: initializes the server with the client UI located at the file path specified by the `TEXT_CAPTURE_CLIENT_PATH` environment variable. If the environment variable is not set, the client UI will be nil.

# Example
```swift
import Foundation
import TextCaptureServer

let semaphore = DispatchSemaphore(value: 0)
do {
  let server = TextCaptureServer()
  let port = 4444
  try server.start(port: port)
  print("Running at http://localhost:\(port)")
  semaphore.wait()
} catch {
  semaphore.signal()
  print("Error: \(error.localizedDescription)")
}
```

## Contributing

If you **have a question**, **found a bug** or want to **propose a feature**, have a look at [the issues page](https://github.com/pepebecker/text-capture-server/issues).
