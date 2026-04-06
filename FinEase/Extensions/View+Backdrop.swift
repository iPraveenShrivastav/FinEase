import SwiftUI

extension View {
    func backdropFilter(blur radius: CGFloat) -> some View {
        self.background(.ultraThinMaterial)
    }
}
