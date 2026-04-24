//
//  ResolverVM.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/23/26.
//

import AtprotoTypes
import AtprotoOAuth
import ATResolve
import Foundation
import SwiftUI
import Microcosm

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
	
	func timer() {
		
		if case .resolving(_, let start, let task) = state {
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
		
	}
}
