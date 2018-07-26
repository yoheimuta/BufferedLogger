# BufferedLogger

[![Build Status](https://app.bitrise.io/app/75f1a12b7326ea09/status.svg?token=-Wus-j9Iq8IVKcFB3wLhSg&branch=master)](https://app.bitrise.io/app/75f1a12b7326ea09)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
<a href="https://swift.org" target="_blank"><img src="https://img.shields.io/badge/Language-Swift4-orange.svg" alt="Language Swift 4"></a>

BufferedLogger is a tiny but thread-safe logger with a buffering and retrying mechanism for iOS.

- Buffer log entries until it's time to output them.
- Batch multiple log entries to use them at the same time.
- Retry outputing log entries when some backoff time elapsed after some errors occurred.

You can use this framework...

- To send a group of log entries to your server.
- To resend them when some errors like a networking trouble is occured.

## Installation

### Carthage

```
github "yoheimuta/BufferedLogger"
```
## Usage

For details, refer to a [Demo project](https://github.com/yoheimuta/BufferedLogger/tree/master/Demo).

### Define your own Writer

Posted log entries are buffered and emitted as a chunk on a routine schedule.

write method is ensured to call serially, which means it is run by a serial queue.

```swift
class MyWriter: Writer {
    func write(_ chunk: Chunk, completion: (Bool) -> Void) {
        // You can implement something useful like uploading logs to your server.
        print("chunk is \(chunk)")

        chunk.entries.forEach {
            print("entry is \($0)")
        }

        completion(true)
    }
}
```

### Make the logger and post a log

You have to register your writer to the logger and can post your log with it from any thread.

A call to post method is no blocking.

```swift
import BufferedLogger

logger = BFLogger(writer: MyWriter())
logger.post("1".data(using: .utf8)!)
logger.post("2".data(using: .utf8)!)
logger.post("3".data(using: .utf8)!)
```

You can also create your configuration for buffering and emitting mechanism.

If you omit to define your configuration, default below is used. Each meaning is in a protocol comment.

```swift
public static let `default` = Config(flushEntryCount: 5,
                                     flushInterval: 10,
                                     retryRule: DefaultRetryRule(retryLimit: 3))

public class DefaultRetryRule: RetryRule {
    public let retryLimit: Int

    public init(retryLimit: Int) {
        self.retryLimit = retryLimit
    }

    public func delay(try count: Int) -> TimeInterval {
        return 2.0 * pow(2.0, Double(count - 1))
    }
}
```

## TODO

- [ ] Stores the unsent entries in the local storage when the application couldn't send log entries.
