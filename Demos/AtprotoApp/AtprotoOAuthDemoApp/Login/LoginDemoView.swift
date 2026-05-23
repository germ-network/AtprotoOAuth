//
//  LoginView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI
import OAuth4Swift

//replace this with the CachedAuthenticationView

struct LoginDemoView: View {
	@State private var viewModel = LoginDemoVM()

	var body: some View {
		VStack(alignment: .center, spacing: 20) {
			switch viewModel.state {
			case .validating(_), .loggedIn(_):
				Button("reset", action: viewModel.reset)
					.apply { view in
						if #available(iOS 17.0, macOS 26.0, *) {
							view.buttonStyle(.glassProminent)
						} else {
							view
						}
					}
			default:
				EmptyView()
			}

			switch viewModel.state {
			case .collectHandle:
				Spacer()
				CollectHandleView(viewModel: viewModel)
			case .validating(let handle):
				Text("Validating \(handle)")
			case .agentCreated(_):
				Text("Agent created. Loading...")
			case .loggedIn(let agent):
				Text("Successfully Logged In")
				Button("Refresh") {
					Task {
						let _ = try await agent.refresh()
					}
				}
			}

			Spacer()

			Section(viewModel.logs.count > 0 ? "Logs" : "") {
				VStack(alignment: .leading, spacing: 10) {
					ForEach(viewModel.logs) { log in
						Text(log.body)
					}
				}
			}
			Spacer()
		}
	}
}

#Preview {
	LoginDemoView()
}
