//
//  ATProtoOAuthSession.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation

//to be moved into own package

public actor ATProtoOAuthSession {

}

extension ATProtoOAuthSession {
	public struct Archive: Codable, Sendable {

	}

	init(archive: Archive) {
		self.init()
	}

	var archive: Archive {
		.init()
	}
}
