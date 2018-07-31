//
//  EntryStorage.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/30.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// EntryStorage is a storage for a set of entry.
public protocol EntryStorage {
    /// retrieveAll gets all logs from the stroage.
    func retrieveAll(from path: String) throws -> Set<Entry>

    /// save adds a log to the storage.
    func save(_ log: Entry, to path: String) throws

    /// remove deletes logs from the storage.
    func remove(_ logs: Set<Entry>, from path: String) throws
}
