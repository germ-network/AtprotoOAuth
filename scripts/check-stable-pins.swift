// check-stable-pins.swift
//
// Guards against releasing a SwiftPM package that carries an unstable
// dependency pin. A dependency pinned by `branch:` or `revision:` cannot be
// resolved by any consumer that depends on THIS package via a version
// requirement — SwiftPM refuses "a stable-version package depends on an
// unstable-version package". So a tagged release must never carry one; if it
// does, the tag is un-consumable and has to be superseded by a fresh release
// (this is exactly what happened to AtprotoOAuth 0.6.1 → 0.6.2).
//
// Reads the output of `swift package dump-package` on stdin (the authoritative,
// comment-proof manifest dump — not a text grep) and exits:
//   0  no branch/revision pins
//   1  one or more unstable pins present (prints them)
//   2  usage / parse error
//
// Usage:  swift package dump-package | swift scripts/check-stable-pins.swift

import Foundation

struct Manifest: Decodable {
    struct Dependency: Decodable {
        struct SourceControl: Decodable {
            struct Location: Decodable {
                struct Remote: Decodable { let urlString: String }
                let remote: [Remote]?
            }
            // `requirement` is a single-key object whose key is the kind:
            // range | exact | branch | revision. Only the key matters here, so
            // the values are decoded into a type that consumes anything.
            struct AnyValue: Decodable { init(from decoder: Decoder) throws {} }
            let location: Location?
            let requirement: [String: AnyValue]
        }
        let sourceControl: [SourceControl]?
    }
    let dependencies: [Dependency]
}

let input = FileHandle.standardInput.readDataToEndOfFile()
guard !input.isEmpty else {
    FileHandle.standardError.write(Data(
        "check-stable-pins: no input on stdin (pipe `swift package dump-package` into this script)\n".utf8))
    exit(2)
}

let manifest: Manifest
do {
    manifest = try JSONDecoder().decode(Manifest.self, from: input)
} catch {
    FileHandle.standardError.write(Data(
        "check-stable-pins: could not parse dump-package JSON: \(error)\n".utf8))
    exit(2)
}

let unstable: Set<String> = ["branch", "revision"]
var offenders: [(kind: String, url: String)] = []
for dependency in manifest.dependencies {
    for sourceControl in dependency.sourceControl ?? [] {
        guard let kind = sourceControl.requirement.keys.first, unstable.contains(kind)
        else { continue }
        let url = sourceControl.location?.remote?.first?.urlString ?? "<unknown>"
        offenders.append((kind, url))
    }
}

guard offenders.isEmpty else {
    var message = "check-stable-pins: FAIL — unstable SwiftPM dependency pin(s) present:\n"
    for offender in offenders { message += "  \(offender.kind): \(offender.url)\n" }
    message += """
        A released package must pin dependencies by version \
        (from: / exact: / .upToNextMinor), not branch:/revision:.
        Re-pin these to tagged releases before publishing.\n
        """
    FileHandle.standardError.write(Data(message.utf8))
    exit(1)
}

print("check-stable-pins: OK — no branch/revision dependency pins")
exit(0)
