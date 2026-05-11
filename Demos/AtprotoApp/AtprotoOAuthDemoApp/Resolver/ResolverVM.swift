//
//  ResolverVM.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/23/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import Foundation
import Microcosm
import SwiftUI

@Observable
final class ResolverVM {
	enum State {
		case collectHandle
		case resolving(handle: String, start: Date, Task<Void, Error>)
		case complete(TimeInterval)
	}
	var state: State = .collectHandle
	var logs: [LogEntry] = []

	var timeElapsed: TimeInterval?

	enum Choices {
		case slingshot
		case atresolve
		case fallback

		var resolver: Atproto.Resolver {
			switch self {
			case .slingshot:
				SlingshotResolver(
					slingshot: .init(resourceFetcher: URLSession.shared)
				)
			case .atresolve:
				ATResolveResolver(resourceFetcher: URLSession.shared)
			case .fallback:
				FallbackResolver.slingshotToDirect
			}
		}
	}
	var choices: Choices = .slingshot

	func timer() {

		if case .resolving(_, let start, _) = state {
			timeElapsed = Date().timeIntervalSince(start)
		} else {
			timeElapsed = nil
		}
	}

	func reset() {
		state = .collectHandle
		logs = []
	}
}

extension ResolverVM: CollectHandleParent {
	func collected(handle: String) {
		let fetchTask = Task {
			logs.append(.init(body: "Starting to resolve \(handle)"))
			let didDoc = try await choices.resolver
				.verifiedResolve(handle: .init(string: handle))

			guard let didDoc else {
				return
			}

			logs.append(
				.init(
					body:
						"Resolved \(handle) to \(didDoc.did) with document:\n\(didDoc.document)"
				))
		}
		let start = Date.now
		state = .resolving(handle: handle, start: start, fetchTask)

		Task {
			do {
				let _ = try await fetchTask.value
				logs.append(.init(body: "Resoultion complete"))
			} catch {
				logs.append(.init(body: "error resolving \(error)"))

			}
			state = .complete(Date().timeIntervalSince(start))
		}
	}
}
