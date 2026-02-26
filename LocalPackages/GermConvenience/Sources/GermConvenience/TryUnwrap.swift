//
//  TryUnwrap.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation

enum UnwrapError: Error {
	case missing(String)
}

extension Optional {
	public var tryUnwrap: Wrapped {
		get throws {
			try tryUnwrap(UnwrapError.missing("\(Wrapped.self)"))
		}
	}

	public func tryUnwrap<E: Error>(_ throwing: E) throws(E) -> Wrapped {
		guard let self else {
			throw throwing
		}
		return self
	}
}
