import SwiftUI

struct DestinationCard: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // Title and Rating on one line
            HStack(alignment: .center) {
                Text(destination.name)
                    .font(.headline)
                    .padding(10)
                Spacer()
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", destination.rating))
                        .font(.subheadline)
                        .padding(10)
                }
            }

            // Location and Avatars row
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .padding(10)
                
                    Text(destination.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
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
                            .padding(10)
                    }
                }
            }
        }
        .frame(width: 260)
        .padding(.bottom, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    DestinationCard(destination: Destination(
        name: "Santorini",
        imageName: "santorini",
        rating: 4.7,
        location: "Greece",
        participantAvatars: ["avatar1", "avatar2", "avatar3", "avatar4"]
    ))
        .previewLayout(.sizeThatFits)
        .padding()
}
