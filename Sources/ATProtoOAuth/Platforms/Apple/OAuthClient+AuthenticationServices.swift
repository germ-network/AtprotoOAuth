//
//  OAuthClient+AuthenticationServices.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/19/26.
//

import OAuthenticator

#if canImport(AuthenticationServices)
	import AuthenticationServices

	extension ASWebAuthenticationSession {
		static public func userAuthenticator() -> Authenticator.UserAuthenticator {
			{
				try await begin(with: $0, callbackURLScheme: $1)
			}
		}
	}
#endif  //canImport(AuthenticationServices)
