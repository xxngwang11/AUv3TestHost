import SwiftUI

struct MetricBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 120, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 20)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * min(value / max(maxValue, 1), 1.0), height: 20)
                }
                .cornerRadius(4)
            }
            .frame(height: 20)
            
            Text(String(format: "%.1f ms", value))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)
        }
    }
}