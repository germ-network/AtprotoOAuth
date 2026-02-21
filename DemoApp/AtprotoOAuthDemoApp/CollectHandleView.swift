//
//  CollectHandleView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI

struct CollectHandleView: View {
	@State private var handle: String = ""
	let viewModel: LoginVM

	var body: some View {
		VStack {
			TextField("atprotoHandle", text: $handle)

			Button("Authenticate") {
				viewModel.login(handle: handle)
			}
		}
	}
}

#Preview {
	CollectHandleView(viewModel: .init())
}
