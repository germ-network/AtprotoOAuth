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
		TextField("atprotoHandle", text: $viewModel.handle)

		Button("Authenticate", action: viewModel.login)
	}
}

#Preview {
	LoginView()
}
