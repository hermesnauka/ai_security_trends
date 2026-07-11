import Foundation
import SwiftData

@Model
public final class CodeSample {
    public var language: CodeLanguage
    public var sampleType: SampleType
    public var title: String
    public var sampleDescription: String
    public var code: String
    public var frameworkHint: String   // "SwiftData #Predicate", "Spring Boot 3.3", "Django ORM"...
    public var versionNote: String
    public var mitigation: Mitigation?

    public init(
        language: CodeLanguage,
        sampleType: SampleType,
        title: String,
        sampleDescription: String,
        code: String,
        frameworkHint: String,
        versionNote: String,
        mitigation: Mitigation? = nil
    ) {
        self.language = language
        self.sampleType = sampleType
        self.title = title
        self.sampleDescription = sampleDescription
        self.code = code
        self.frameworkHint = frameworkHint
        self.versionNote = versionNote
        self.mitigation = mitigation
    }
}
