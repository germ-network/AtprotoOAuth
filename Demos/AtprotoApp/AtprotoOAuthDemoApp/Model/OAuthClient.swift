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
			clientId:
				"https://static.germnetwork.com/client-metadata.json",
			scopes: ["atproto", "transition:generic"],
			redirectURI: URL(string: "com.germnetwork.static:/oauth")!
		)
	}
}
