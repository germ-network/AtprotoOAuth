//
//  ConditionalApply.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 3/27/26.
//

import Foundation
import SwiftUI

extension View {
	func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
