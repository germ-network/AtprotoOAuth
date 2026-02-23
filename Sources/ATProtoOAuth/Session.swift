//
//  ATProtoOAuthSession.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation
import OAuth

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

public actor ATProtoOAuthSession {
	enum State {
		case active(SessionState)
		case expired
	}
	var state: State

	private init(state: State) {
		self.state = state
	}
}

extension ATProtoOAuthSession {
	init(archive: SessionState.Archive) {
		self.init(state: .active(.init(archive: archive)))
	}

	//if expired not worth saving
	var archive: SessionState.Archive? {
		guard case .active(let sessionState) = state else {
			return nil
		}
		return sessionState.archive
	}
}
