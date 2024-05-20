//
// Copyright (c) 2023 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import Foundation

public enum MetricsFileName {
    public static let binarySize = "binary_size.json"
    public static let codeCoverage = "code_coverage.json"
}

public struct HealthMetricsFile<T: Codable>: Codable {
    public struct Module<U: Codable>: Codable {
        public var name: String
        public var commits: [Commit<U>]

        public init(name: String, commits: [Commit<U>]) {
            self.name = name
            self.commits = commits
        }
    }

    public struct Commit<V: Codable>: Codable {
        public var hash: String
        public var metricsData: V

        public init(hash: String, metricsData: V) {
            self.hash = hash
            self.metricsData = metricsData
        }
    }

    public var modules: [Module<T>]

    public subscript(moduleNamed: String) -> Module<T>? {
        get {
            self.modules.first { $0.name == moduleNamed }
        }
        set {
            if let idx = self.modules.firstIndex(where: { $0.name == moduleNamed }) {
                if let newValue {
                    self.modules[idx] = newValue
                } else {
                    self.modules.remove(at: idx)
                }
            } else {
                if let newValue {
                    self.modules.append(newValue)
                }
            }
        }
    }

    public init(modules: [Module<T>]) {
        self.modules = modules
    }
}

extension HealthMetricsFile {
    public func findCommit(
        moduleName: String,
        commitHash: String
    ) -> Commit<T>? {
        self[moduleName]?
            .commits
            .first { $0.hash == commitHash }
    }

    public mutating func modifyCommit(
        moduleName: String,
        commitHash: String,
        metricsData: T
    ) {
        var module = self[moduleName] ?? Module(name: moduleName, commits: [])
        var commit = module[commitHash] ?? Commit(
            hash: commitHash,
            metricsData: metricsData
        )
        commit.metricsData = metricsData
        module[commitHash] = commit
        self[moduleName] = module
    }
}

extension HealthMetricsFile.Module {
    public subscript(commitHash: String) -> HealthMetricsFile.Commit<U>? {
        get {
            self.commits.first { $0.hash == commitHash }
        }
        set {
            if let idx = self.commits.firstIndex(where: { $0.hash == commitHash }) {
                if let newValue {
                    self.commits[idx] = newValue
                } else {
                    self.commits.remove(at: idx)
                }
            } else {
                if let newValue {
                    self.commits.append(newValue)
                }
            }
        }
    }
}

extension HealthMetricsFile {
    public static func file(at path: URL) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let data = try Data(contentsOf: path)
        return try decoder.decode(Self.self, from: data)
    }
}
