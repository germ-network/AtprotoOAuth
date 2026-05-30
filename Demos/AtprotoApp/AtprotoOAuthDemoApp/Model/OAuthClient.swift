//
//  OAuthClient.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/7/26.
//

import Foundation
import OAuth4Swift

extension OAuth.ClientInfo {
	static var demo: Self {
		.init(
			clientId: clientIdString,
			scopes: [
				"atproto",
				"rpc:app.bsky.actor.getProfile?aud=did:web:api.bsky.app#bsky_appview",
				"rpc:app.bsky.graph.getKnownFollowers?aud=did:web:api.bsky.app#bsky_appview",
				"include:com.germnetwork.authManageDeclaration",
				"repo:app.bsky.graph.block?action=create&action=delete",
			],
			redirectURI: URL(string: redirectUriString)!
		)
	}

	private static var clientIdString: String {
		#if DEBUG
			"https://beta.germdm.org/oauth-client-metadata.json"
		#else
			"https://germdm.app/oauth-client-metadata.json"
		#endif
	}

	//use custom url scheme on iOS, and universal link if running iOS on Mac
	private static var redirectUriString: String {
		if ProcessInfo.processInfo.isiOSAppOnMac {
			#if DEBUG
				"https://beta.germdm.org/oauth/callback"
			#else
				"https://germdm.app/oauth/callback"
			#endif

		} else {
			#if DEBUG
				"org.germdm.beta:/callback"
			#else
				"app.germdm:/callback"
			#endif
		}
	}
}
