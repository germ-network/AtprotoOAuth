//
//  Utf8Data.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 3/1/26.
//

import Foundation

extension String {
	public var utf8Data: Data {
		Data(utf8)
	}
}
