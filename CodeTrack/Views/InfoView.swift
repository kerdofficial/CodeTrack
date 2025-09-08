//
//  InfoView.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI

struct InfoView: View {
  var body: some View {
    ZStack {
      ScrollView {
        VStack(spacing: 16) {
          VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
              .font(.system(size: 64))
              .foregroundColor(.blue)

            Text("CodeTrack")
              .font(.title)
              .fontWeight(.bold)

            Text("Version 1.0.5")
              .font(.headline)
              .foregroundColor(.secondary)

            Text("Track your daily coding activity with a beautiful GitHub-style widget.")
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.vertical)

          GroupBox {
            VStack(spacing: 12) {
              Text("Feel free to contribute!")
                .font(.headline)

              Text("This app is open source and welcomes contributions from the community.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 360)

              Link(destination: URL(string: "https://github.com/kerdofficial/CodeTrack")!) {
                HStack {
                  Text("View on GitHub")
                }
                .foregroundColor(.white)
              }
              .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity)
          }
        }
        .padding(24)
        .frame(maxWidth: 640)
      }

      VStack {
        Spacer()
        Text("© 2025 KerD")
          .font(.caption)
          .foregroundColor(.secondary.opacity(0.7))
          .padding()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  InfoView()
}
