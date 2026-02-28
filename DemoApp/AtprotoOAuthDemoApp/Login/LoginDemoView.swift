//
//  LoginView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI

struct LoginDemoView: View {
	@State private var viewModel = LoginDemoVM()

	var body: some View {
		VStack {
			switch viewModel.state {
			case .collectHandle:
				CollectHandleView(viewModel: viewModel)
			case .validating(let handle):
				Text("Validating \(handle)")
				Button("reset", action: viewModel.reset)
			case .loggedIn(_):
				Text("Successfully Logged In")
				Button("reset", action: viewModel.reset)
			}

			VStack {
				ForEach(viewModel.logs) { log in
					Text(log.body)
				}
			}
		}
	}
}

#Preview {
	LoginDemoView()
}
