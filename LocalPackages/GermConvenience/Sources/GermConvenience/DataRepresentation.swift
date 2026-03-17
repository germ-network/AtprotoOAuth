//
//  DataRepresentation.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 3/17/26.
//

import Foundation

//useful for getting raw bytes e.g. from a Symmetric Key
extension ContiguousBytes {
	public var dataRepresentation: Data {
		withUnsafeBytes {
			Data(Array($0))
		}
	}
}
