import AtprotoTypes
import Foundation
import GermConvenience
import Microcosm
import SwiftUI

@Observable final class SlingshotVM {
	let slingshot = Microcosm.Slingshot(
		resourceFetcher: URLSession.shared
	)

	var handle: String = ""
	var did: String = ""
	var pds: String = ""

	enum State {
		case start
		case fetching(String)
		case resolved
	}
	var state: State = .start

	struct LogEntry: Identifiable {
		let id: UUID = .init()
		let body: String
	}
	var logs: [LogEntry] = []

	func reset() {
		state = .start
		logs = []
		handle = ""
		did = ""
		pds = ""
	}

	func fetchIdentity(identifier: String) {
		state = .fetching(identifier)
		Task {
			do {
				logs.append(.init(body: "Fetching \(identifier)"))
				let result = try await slingshot.resolveMiniDoc(
					identifier: identifier)

				logs.append(.init(body: "Resolved \(identifier)"))
				guard let identity = result else {
					logs.append(
						.init(
							body:
								"Error: Identity not found: \(identifier)"
						))

					state = .start
					return
				}

				self.did = identity.did.stringRepresentation
				self.handle = identity.handle
				self.pds = identity.pds.absoluteString

				state = .resolved
			} catch {
				state = .start
				logs.append(.init(body: "Error: \(error)"))
			}
		}
	}
}
