#if DEBUG
import UIKit

enum ProImageUITestFixtures {
    @MainActor static func seedIfRequested(_ library: ProImageStore) async throws {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("RECALL_UI_TEST_ISOLATED"),
              arguments.contains("RECALL_UI_TEST_PRO_IMAGES"), library.cards.isEmpty else { return }
        for index in (0..<10).reversed() {
            let size = index % 3 == 0 ? CGSize(width: 900, height: 1_400)
                : (index % 3 == 1 ? CGSize(width: 1_200, height: 720) : CGSize(width: 900, height: 900))
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor(red: 0.05, green: 0.12, blue: 0.20, alpha: 1).setFill()
                context.fill(CGRect(origin: .zero, size: size))
                let title = "POSTER \(index + 1)"
                title.draw(at: CGPoint(x: 60, y: 80), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 64, weight: .bold), .foregroundColor: UIColor.white
                ])
                for row in 0..<8 {
                    let y = CGFloat(220 + row * 120)
                    "\(row + 1). Read the details. Keep the original.".draw(at: CGPoint(x: 60, y: y), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 24), .foregroundColor: UIColor.white
                    ])
                }
            }
            guard let data = image.pngData() else { throw ProImageError.unreadableImage }
            try await library.save(data: data, title: "Poster \(index + 1)", source: "https://example.com/poster/\(index + 1)",
                                   notes: "Original poster notes \(index + 1)")
        }
    }
}
#endif
