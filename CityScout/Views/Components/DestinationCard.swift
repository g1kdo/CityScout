import SwiftUI

struct DestinationCard: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ─── Image ──────────────────────────────────────────
            ZStack(alignment: .topTrailing) {
                Image(destination.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 260, height: 300)
                    .clipped()
                    .cornerRadius(16)

                Image(systemName: "bookmark")
                    .font(.system(size: 20))
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .padding(10)
            }

            // ─── Title & Rating ──────────────────────────────────
            HStack {
                Text(destination.name)
                    .font(.headline)
                    .lineLimit(1)                     // Prevent wrapping
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", destination.rating))
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)

            // ─── Location & Avatars ─────────────────────────────
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .frame(width: 16, height: 16)
                    Text(destination.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)                 // Prevent wrapping
                }

                Spacer()

                HStack(spacing: -12) {
                    ForEach(destination.participantAvatars.prefix(3), id: \.self) { imageName in
                        AvatarViewLocal(imageName: imageName, size: 32)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    if destination.participantAvatars.count > 3 {
                        Text("+\(destination.participantAvatars.count - 3)")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 260)                          // Fixed width ensures uniform layout
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}


