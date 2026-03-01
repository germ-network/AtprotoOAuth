//
//  InMemorySessionStore.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/28/26.
//

import AtprotoTypes
import Foundation
import OAuth
import SwiftUI

//A backing store for one session (e.g. if you had one model object per account)
//and store one session per account

@MainActor
@Observable
final class InMemorySessionStore {
	let did: Atproto.DID
	var sessionArchive: SessionState.Archive?

	init(did: Atproto.DID, sessionArchive: SessionState.Archive? = nil) {
		self.did = did
		self.sessionArchive = sessionArchive
	}
}
