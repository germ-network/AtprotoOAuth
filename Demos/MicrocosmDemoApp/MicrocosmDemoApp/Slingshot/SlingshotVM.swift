import Foundation
import GermConvenience
import Microcosm
import SwiftUI

@Observable final class SlingshotVM {
	let slingshot = Slingshot(
		resourceFetcher: URLSession.shared
	)

	enum State {
		case collectHandle
		case validating(String)
		case resolved
	}
	var state: State = .collectHandle

	struct LogEntry: Identifiable {
		let id: UUID = .init()
		let body: String
	}
	var logs: [LogEntry] = []

	func reset() {
		state = .collectHandle
		logs = []
	}
}
