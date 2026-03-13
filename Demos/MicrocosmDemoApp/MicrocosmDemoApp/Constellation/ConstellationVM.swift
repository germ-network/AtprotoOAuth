import Foundation
import Microcosm
import SwiftUI

@Observable final class ConstellationVM {
	enum State {
		case start
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
	}
}
