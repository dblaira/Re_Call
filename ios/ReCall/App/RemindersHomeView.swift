import SwiftUI

/// The Reminders tab: an editorial "home" matching the Figma frame — a black "Notorious" hero,
/// a tan RECALL band of story cards, and a two-column grid of reminder-shape tiles. The actual
/// reminder list lives on the Tasks tab.
struct RemindersHomeView: View {
    /// Tapping a story card or shape tile starts a new reminder seeded with a title.
    var onPick: (String) -> Void = { _ in }

    private let stories: [BandCardSpec] = [
        .init(title: "Build a basic reminder app", bg: .white,          fg: Brand.nearBlack, accent: Brand.tan),
        .init(title: "Drawing by Seeing / Gestalt meets UI", bg: Brand.darkRed, fg: .white, accent: Brand.crimson),
        .init(title: "Quick kill switch",          bg: Brand.nearBlack, fg: .white,          accent: Brand.crimson),
        .init(title: "Capture first / Organize later", bg: Brand.cyan,  fg: Brand.tileBlue,  accent: Brand.crimson),
    ]
    private let leftTiles: [ShapeTileSpec] = [
        .init(title: "Add one movement",       bg: Brand.tileBlue, fg: .white, tags: ["PHOTO", "TIME", "URL"], height: 190, dark: true),
        .init(title: "Pay before due",         bg: .white,         fg: .black, tags: ["DATE"],                 height: 135, dark: false),
        .init(title: "Bring this when I leave", bg: Brand.tileGray, fg: .black, tags: ["PLACE", "PHOTO"],       height: 150, dark: false),
    ]
    private let rightTiles: [ShapeTileSpec] = [
        .init(title: "Text them back",        bg: Brand.darkRed, fg: .white, tags: ["PERSON"],     height: 190, dark: true),
        .init(title: "Do this after workout", bg: Brand.tileDark, fg: .white, tags: ["TIME", "CUE"], height: 190, dark: true),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                Rectangle().fill(Brand.crimson).frame(height: 2)
                band
                shapes
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        Text("Notorious")
            .font(Brand.serif(48))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.bottom, 18)
            .padding(.horizontal, 16)
            .background(Brand.nearBlack)
    }

    private var band: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECALL")
                    .font(.system(size: 15, weight: .heavy)).tracking(2.5)
                    .foregroundStyle(Brand.recallBlue)
                Spacer()
                Text("See all")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Brand.crimson)
            }
            ForEach(stories) { spec in
                Button { onPick(spec.title) } label: { BandCard(spec: spec) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.tan)
    }

    private var shapes: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminder shapes")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.black)
                Spacer()
                Text("Edit")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Brand.crimson)
            }
            HStack(alignment: .top, spacing: 10) {
                column(leftTiles)
                column(rightTiles)
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 150)   // clearance for the FAB + tab bar
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private func column(_ tiles: [ShapeTileSpec]) -> some View {
        VStack(spacing: 10) {
            ForEach(tiles) { spec in
                Button { onPick(spec.title) } label: { ShapeTile(spec: spec) }
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Story card

struct BandCardSpec: Identifiable {
    let id = UUID()
    let title: String
    let bg: Color
    let fg: Color
    let accent: Color
}

struct BandCard: View {
    let spec: BandCardSpec
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(spec.title)
                .font(Brand.serif(27, weight: .regular))
                .foregroundStyle(spec.fg)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(spec.accent).frame(width: 36, height: 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(spec.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08)))
    }
}

// MARK: - Shape tile

struct ShapeTileSpec: Identifiable {
    let id = UUID()
    let title: String
    let bg: Color
    let fg: Color
    let tags: [String]
    let height: CGFloat
    let dark: Bool
}

struct ShapeTile: View {
    let spec: ShapeTileSpec
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grip
            Spacer(minLength: 8)
            VStack(alignment: .leading, spacing: 11) {
                Text(spec.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(spec.fg)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    ForEach(spec.tags, id: \.self) { tag in tagPill(tag) }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: spec.height, alignment: .topLeading)
        .background(spec.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(spec.dark ? Color.white.opacity(0.14) : Color.black.opacity(0.1)))
    }

    private var grip: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
            RoundedRectangle(cornerRadius: 1).frame(width: 3, height: 15)
        }
        .foregroundStyle(spec.fg.opacity(0.5))
    }

    private func tagPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy)).tracking(0.3)
            .foregroundStyle(spec.fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((spec.dark ? Color.white : Color.black).opacity(spec.dark ? 0.16 : 0.06))
            .clipShape(Capsule())
    }
}
