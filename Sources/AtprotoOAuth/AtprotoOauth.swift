//
//  AtprotoOauth.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/9/26.
//

import Foundation
import GermConvenience
import OAuth

extension AuthComponents {
	static func atproto(
		appCredentials: AppCredentials,
		authFetcher: HTTPFetcher,
		dpopSigner: DPoPSigning
	) -> AuthComponents {
		.init(
			additionalParameters: [
				"client_id": appCredentials.clientId,
				"redirect_url": appCredentials.callbackURL.absoluteString,
			],
			authFetcher: authFetcher,
			validator: { authServerMetadata, tokenResponse in
				//TODO: finish validation

				.init(
					accessToken: .init(
						value: tokenResponse.accessToken,
						expiresIn: tokenResponse.expiresIn
					),
					refreshToken: .init(
						refreshToken: tokenResponse.refreshToken),
					scopes: tokenResponse.scope,
					//REVIEW: where should this come from?
					issuingServer: authServerMetadata.issuer
				)
			},
			dpopSigner: dpopSigner
		)
	}
}
