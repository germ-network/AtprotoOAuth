//
//  CollectHandleView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI

struct CollectHandleView: View {
	@State private var handle: String = ""
	let viewModel: LoginDemoVM

	var body: some View {
		VStack(alignment: .center) {
			HStack(alignment: .center) {
				Spacer()
				HStack {
					Text("@").foregroundStyle(.blue)
					TextField("username.bsky.social", text: $handle)
						.onSubmit {
							viewModel.login(
								handle: handle)
						}
						.keyboardType(.URL)
						.autocorrectionDisabled()
						#if os(iOS)
							.textInputAutocapitalization(.never)
						#else
						#endif
				}
				.padding()
				.overlay(
					RoundedRectangle(
						cornerRadius: 16
					).stroke(.blue, lineWidth: 2)
				)
				Spacer()
			}

			Button("Authenticate") {
				viewModel.login(handle: handle)
			}
			.buttonStyle(.glassProminent)
		}
	}
}

#Preview {
	CollectHandleView(viewModel: .init())
}
