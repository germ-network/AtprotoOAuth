//
//  LoginView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import SwiftUI

//replace this with the CachedAuthenticationView

struct ConstellationView: View {
	@State private var viewModel = ConstellationVM()

	var body: some View {
		VStack {
			switch viewModel.state {
			case .start:
				Text("TODO")
			}

			VStack {
				Text("Logs").bold()
				ForEach(viewModel.logs) { log in
					Text(log.body)
				}
			}
		}
	}
}

#Preview {
	ConstellationView()
}
