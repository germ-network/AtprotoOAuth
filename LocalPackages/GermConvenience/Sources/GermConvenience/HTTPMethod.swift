//
//  HTTPMethod.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 2/26/26.
//

//from Dave Delong
//https://davedelong.com/blog/2020/06/28/http-in-swift-part-2-basic-structures/
//Since the HTTP spec allows for any single-word method, defining this value in Swift as an enum is incorrect, because an enum only allows for a finite number of values, but there are an infinite number of possible “single word” values. A better implementation of this is to use a struct
public struct HTTPMethod: Hashable, Sendable {
	public static let get = HTTPMethod(rawValue: "GET")
	public static let post = HTTPMethod(rawValue: "POST")
	public static let put = HTTPMethod(rawValue: "PUT")
	public static let delete = HTTPMethod(rawValue: "DELETE")

	public let rawValue: String
}
