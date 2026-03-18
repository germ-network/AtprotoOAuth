//
//  ContentView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import Microcosm
import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
			Tab("Slingshot", systemImage: "person") {
				SlingshotView()
			}
			Tab("Constellation", systemImage: "person") {
				ConstellationView()
			}
		}
		.padding()
	}
}

#Preview {
	ContentView()
}
