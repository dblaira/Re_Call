import Foundation

/// Presentation only: moving a card never rewrites its image or metadata.
struct ProLibraryArrangement: Codable, Equatable {
    struct Area: Codable, Identifiable, Equatable {
        enum Style: String, Codable { case grid, row }
        let id: UUID
        var style: Style
        var cardIDs: [UUID]

        init(id: UUID = UUID(), style: Style, cardIDs: [UUID] = []) {
            self.id = id; self.style = style; self.cardIDs = cardIDs
        }
    }

    var areas: [Area]

    init(cardIDs: [UUID]) {
        // Stable before the first layout write, so the first user action can
        // address the same area when the archive loads it again.
        let initialID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
        areas = [Area(id: initialID, style: .grid, cardIDs: cardIDs)]
    }

    /// Old collections stay in their existing order. Newly imported images appear
    /// at the top; deleted or duplicate references never hide a surviving image.
    func reconciled(with cardIDs: [UUID]) -> Self {
        var result = self
        var seen = Set<UUID>()
        let available = Set(cardIDs)
        var areaIDs = Set<UUID>()
        result.areas = areas.map { area in
            let id = areaIDs.insert(area.id).inserted ? area.id : UUID()
            return Area(id: id, style: area.style, cardIDs: area.cardIDs.filter {
                available.contains($0) && seen.insert($0).inserted
            })
        }
        if result.areas.first?.style != .grid { result.areas.insert(Area(style: .grid), at: 0) }
        let newCards = cardIDs.filter { !seen.contains($0) }
        result.areas[0].cardIDs.insert(contentsOf: newCards, at: 0)
        return result
    }

    mutating func move(_ cardID: UUID, to areaID: UUID, before target: UUID? = nil) {
        guard cardID != target,
              let source = areas.firstIndex(where: { $0.cardIDs.contains(cardID) }),
              let destination = areas.firstIndex(where: { $0.id == areaID }),
              target == nil || areas[destination].cardIDs.contains(target ?? cardID) else { return }
        areas[source].cardIDs.removeAll { $0 == cardID }
        let insertion = target.flatMap { areas[destination].cardIDs.firstIndex(of: $0) }
            ?? areas[destination].cardIDs.count
        areas[destination].cardIDs.insert(cardID, at: insertion)
    }

    mutating func shift(_ cardID: UUID, by offset: Int) {
        guard let area = areas.firstIndex(where: { $0.cardIDs.contains(cardID) }),
              let index = areas[area].cardIDs.firstIndex(of: cardID),
              areas[area].cardIDs.indices.contains(index + offset) else { return }
        areas[area].cardIDs.swapAt(index, index + offset)
    }

    /// Start a smaller row at this exact position, keeping the cards before and
    /// after it in their own full-size areas. Other row membership stays untouched.
    mutating func startRow(at cardID: UUID) {
        guard let area = areas.firstIndex(where: { $0.style == .grid && $0.cardIDs.contains(cardID) }),
              let index = areas[area].cardIDs.firstIndex(of: cardID) else { return }
        let following = Array(areas[area].cardIDs.dropFirst(index + 1))
        areas[area].cardIDs = Array(areas[area].cardIDs.prefix(index))
        areas.insert(contentsOf: [Area(style: .row, cardIDs: [cardID]),
                                  Area(style: .grid, cardIDs: following)], at: area + 1)
    }

    mutating func addRow(after areaID: UUID) {
        guard let index = areas.firstIndex(where: { $0.id == areaID }) else { return }
        areas.insert(contentsOf: [Area(style: .row), Area(style: .grid)], at: index + 1)
    }

    /// Removing a row changes its presentation, never the user's saved images.
    mutating func removeRow(_ areaID: UUID) {
        guard let index = areas.firstIndex(where: { $0.id == areaID && $0.style == .row }) else { return }
        areas[index].style = .grid
        var merged: [Area] = []
        for area in areas {
            if area.style == .grid, merged.last?.style == .grid {
                merged[merged.count - 1].cardIDs.append(contentsOf: area.cardIDs)
            } else { merged.append(area) }
        }
        areas = merged
    }

    func name(for area: Area) -> String {
        guard let index = areas.firstIndex(where: { $0.id == area.id }) else { return "Cards" }
        let rowCount = areas.prefix(index + 1).filter { $0.style == .row }.count
        if area.style == .row { return "Row \(rowCount)" }
        return rowCount == 0 ? "Top cards" : "Cards below row \(rowCount)"
    }
}
