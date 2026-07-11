import Foundation
import SwiftData

@Model
public final class Framework {
    @Attribute(.unique) public var code: String   // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    public var name: String
    public var version: String
    public var frameworkDescription: String
    public var referenceUrl: String
    @Relationship(deleteRule: .cascade, inverse: \Threat.framework) public var threats: [Threat] = []

    public init(code: String, name: String, version: String, frameworkDescription: String, referenceUrl: String) {
        self.code = code
        self.name = name
        self.version = version
        self.frameworkDescription = frameworkDescription
        self.referenceUrl = referenceUrl
    }
}
