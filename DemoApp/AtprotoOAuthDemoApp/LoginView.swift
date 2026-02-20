//
//  LoginView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI

struct LoginView: View {
	@State private var viewModel = LoginVM()

	var body: some View {
		VStack {
			switch viewModel.state {
			case .collectHandle:
				CollectHandleView(viewModel: viewModel)
			case .validating(let handle):
				Text("Validating \(handle)")
				Button("reset", action: viewModel.reset)
			}

			VStack {
				ForEach(viewModel.log) { log in
					Text(log.body)
				}
			}
		}
	}
}

#Preview {
	LoginView()
}
