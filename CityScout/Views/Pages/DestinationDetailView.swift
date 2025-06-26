import SwiftUI

struct DestinationDetailView: View {
  let destination: Destination
  @State private var showFullDescription = false
    @Environment(\.dismiss) private var dismiss


  // tweak these to taste
  private let headerHeight: CGFloat = 350
  private let detailCornerRadius: CGFloat  = 32
  private let overlapAmount: CGFloat = 60

  var body: some View {
    ZStack(alignment: .top) {
      // ── 1) Header Image ─────────────────────
      Image(destination.imageName)
        .resizable()
        .scaledToFill()
        .frame(height: headerHeight)
        .frame(maxWidth: .infinity)
        .clipped()
       
        .ignoresSafeArea(edges: .top)
     

      // ── 2) Custom Nav Bar ───────────────────
      HStack {
          Button {
              dismiss()
          }
          label: {
          Image(systemName: "chevron.left")
            .foregroundColor(.white)
            .padding(8)
            .background(Circle().fill(Color.black.opacity(0.3)))
        }
        Spacer()
        Text("Details")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Button { /* bookmark */ } label: {
          Image(systemName: "bookmark")
            .foregroundColor(.white)
            .padding(8)
            .background(Circle().fill(Color.black.opacity(0.3)))
        }
      }
      .padding(.horizontal)
     

      // ── 3) Overlapping Card + Button ────────
      VStack(spacing: 0) {
        // push down so card overlaps by exactly overlapAmount
        Spacer().frame(height: headerHeight - overlapAmount)

        // white card
        VStack(spacing: 16) {
          headerRow
          statsRow
          galleryRow
          aboutRow
            
          Spacer(minLength: 0)
        }
        .padding()
        .background(
          Color.white
            .clipShape(
              RoundedCorners(radius: detailCornerRadius, corners: [.topLeft, .topRight])
            )
        )
        .offset(y: -(detailCornerRadius))

        // Book Now button
        Button("Book Now") { /* book action */ }
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(hex: "#24BAEC"))
          .cornerRadius(12)
          .padding(.horizontal)
          .padding(.bottom, safeBottom())
      }
    }
  }

  // ── Sections ───────────────────────────────

  private var headerRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(destination.name)
          .font(.title2).bold()
        Text(destination.location)
          .font(.subheadline)
          .foregroundColor(.gray)
      }
      Spacer()
      Image("LocalAvatarImage")
        .resizable()
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
  }

  private var statsRow: some View {
    HStack(spacing: 16) {
      HStack(spacing: 4) {
        Image(systemName: "mappin.and.ellipse")
        Text(destination.location)
      }
      .font(.subheadline).foregroundColor(.gray)

      HStack(spacing: 4) {
        Image(systemName: "star.fill").foregroundColor(.yellow)
        Text(String(format: "%.1f", destination.rating))
        Text("(2498)")
      }
      .font(.subheadline)
      .foregroundColor(.gray)

      Spacer()

      Text("$59/Person")
        .font(.subheadline)
        .foregroundColor(Color(hex: "#24BAEC"))
    }
  }

  private var galleryRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        let thumbs = destination.participantAvatars.prefix(5)
        ForEach(Array(thumbs), id: \.self) { img in
          Image(img)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .cornerRadius(12)
        }
        if destination.participantAvatars.count > 5 {
          let more = destination.participantAvatars.count - 5
          Text("+\(more)")
            .font(.subheadline).bold()
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.black)
        }
      }
      .padding(.vertical, 8)
    }
  }

  private var aboutRow: some View {
      VStack(alignment: .leading, spacing: 4) {
        let full = destination.description
        let truncated = String(full.prefix(150)) + "…"

        Text(showFullDescription ? full : truncated)
          .font(.body)
          .foregroundColor(.gray)

        if !showFullDescription && full.count > 150 {
          Button("Read More") {
            withAnimation { showFullDescription = true }
          }
          .font(.subheadline)
          .foregroundColor(Color(hex: "#FF7029"))
        }
      }

      
  }

  // ── Safe-area helpers ──────────────────────

    private func safeTop() -> CGFloat {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .windows
        .first?
        .safeAreaInsets.top ?? 0
    }

    private func safeBottom() -> CGFloat {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .windows
        .first?
        .safeAreaInsets.bottom ?? 0
    }

}

// ── Only helper in this file ───────────────

struct RoundedCorners: Shape {
  var radius: CGFloat
  var corners: UIRectCorner
  func path(in rect: CGRect) -> Path {
    Path(UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    ).cgPath)
  }
}

// ── Preview ─────────────────────────────────

struct DestinationDetailView_Previews: PreviewProvider {
  static var previews: some View {
    DestinationDetailView(destination:
      Destination(
        name: "Nyandungu Eco Park",
        imageName: "Nyandungu",
        rating: 4.7,
        location:    "Kigali, Nyandungu",
        participantAvatars: Array(repeating: "Nyandungu", count: 8),
        description: String(repeating: "This is an amazing spot. ", count: 20)
      )
    )
  }
}
