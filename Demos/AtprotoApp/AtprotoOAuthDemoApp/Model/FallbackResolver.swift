//
//  FallbackResolver.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/17/26.
//

import AtprotoOAuth
import Foundation
import Microcosm

extension FallbackResolver {
	static var slingshotToDirect: Self {
		.init(
			defaultResolver: SlingshotResolver(
				slingshot: .init(resourceFetcher: URLSession.shared)
			),
			fallbackResolver: ATResolveResolver(
				resourceFetcher: URLSession.shared
			)
		)
	}
}
