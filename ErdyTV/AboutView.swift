import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 5) {
                Text("ErdyTV")
                    .font(.largeTitle)
                    .bold()
                
                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 10) {
                Text("Source Code Repository:")
                    .font(.headline)
                
                Link("https://github.com/erdyizm/ErdyTV", destination: URL(string: "https://github.com/erdyizm/ErdyTV")!)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("© 2025 ErdyTV. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .frame(width: 350, height: 300)
    }
}

#Preview {
    AboutView()
}
