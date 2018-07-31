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

## Runtime Requirements

- iOS 9.0 or later
- Xcode 9.x - Swift4

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

If you omit to define your configuration, default below is used. Each meaning is in a comment.

```swift
/// Config represents a configuration for buffering and writing logs.
public struct Config {
    /// flushEntryCount is the maximum number of entries per one chunk.
    /// When the number of entries of buffer reaches this count, it starts to write a chunk.
    public let flushEntryCount: Int

    /// flushInterval is a interval to write a chunk.
    public let flushInterval: TimeInterval

    /// retryRule is a rule of retry.
    public let retryRule: RetryRule

    /// maxEntryCountInStorage is a max count of entry to be saved in the storage.
    /// When the number of entries in the storage reaches this count, it starts to
    /// delete the older entries.
    public let maxEntryCountInStorage: Int

    /// storagePath is a path to the entries.
    /// When you uses multiple BFLogger, you must set an unique path.
    public let storagePath: String

    public init(flushEntryCount: Int = 5,
                flushInterval: TimeInterval = 10,
                retryRule: RetryRule = DefaultRetryRule(retryLimit: 3),
                maxEntryCountInStorage: Int = 1000,
                storagePath: String = defaultStoragePath) {
        self.flushEntryCount = flushEntryCount
        self.flushInterval = flushInterval
        self.retryRule = retryRule
        self.maxEntryCountInStorage = maxEntryCountInStorage
        self.storagePath = storagePath
    }

    /// default is a default configuration.
    public static let `default` = Config()
}
```

# Persistence

BufferedLogger stores the unsent entries in the local storage when the application couldn't send log entries.

By default, it stores them in local files in the Library/Caches directory.

You can also define your own custom log entry storage backed by any storage system.

See the EntryStroage protocol for more details.
