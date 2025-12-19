//import SwiftUI
//
//public struct NowPlayingHoverView: View {
//    public let artist: String
//    public let title: String
//
//    public var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            Text(artist.isEmpty ? "" : artist)
//                .font(.headline.weight(.bold))
//                .foregroundColor(artist.isEmpty ? .secondary : .primary)
//            Text(title)
//                .font(.subheadline)
//                .lineLimit(2)
//        }
//        .padding(8)
//        .frame(minWidth: 150, alignment: .leading)
//    }
//
//    public init(artist: String, title: String) {
//        self.artist = artist
//        self.title = title
//    }
//}
//
//#Preview {
//    NowPlayingHoverView(artist: "The Beatles", title: "Let It Be")
//}
