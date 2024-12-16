import SwiftUI

struct SocialMediaLinksView: View {
    let links: [SocialMediaLink]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Social Media Links:")
                .font(.headline)
            ForEach(links, id: \.self) { link in
                if let url = URL(string: link.url ?? "") {
                    Link(link.platform ?? "Unknown", destination: url)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
