import SwiftUI
import AVFoundation

/// 通用参数控制界面 —— 当插件未提供自定义 UI 时自动展示
struct GenericParameterView: View {
    let parameterTree: AUParameterTree

    @State private var paramValues: [AUParameterAddress: Float] = [:]

    /// 参数变化检测阈值（避免浮点误差引起的不必要更新）
    private let parameterChangeThreshold: Float = 0.001

    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("参数控制")
                    .font(.headline)
                Spacer()
                Text("通用界面")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("此插件未提供自定义界面，以下为自动生成的参数控制。")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(parameterTree.allParameters, id: \.address) { param in
                        parameterRow(param)
                    }
                }
            }
            .frame(maxHeight: 350)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
        .onAppear { pollAll() }
        .onReceive(timer) { _ in pollAll() }
    }

    // MARK: - 单个参数行

    @ViewBuilder
    private func parameterRow(_ param: AUParameter) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(param.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(displayString(for: param))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            if param.unit == .boolean {
                Toggle("", isOn: boolBinding(for: param))
                    .labelsHidden()
            } else {
                Slider(
                    value: currentBinding(for: param),
                    in: param.minValue...param.maxValue
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Display

    private func displayString(for param: AUParameter) -> String {
        var value = paramValues[param.address] ?? param.value
        return withUnsafePointer(to: &value) { param.string(fromValue: $0) }
    }

    // MARK: - Bindings

    private func currentBinding(for param: AUParameter) -> Binding<Float> {
        Binding(
            get: { paramValues[param.address] ?? param.value },
            set: { newValue in
                paramValues[param.address] = newValue
                param.value = newValue
            }
        )
    }

    private func boolBinding(for param: AUParameter) -> Binding<Bool> {
        Binding(
            get: { (paramValues[param.address] ?? param.value) >= 0.5 },
            set: { newValue in
                let v: Float = newValue ? 1.0 : 0.0
                paramValues[param.address] = v
                param.value = v
            }
        )
    }

    // MARK: - Polling

    private func pollAll() {
        for param in parameterTree.allParameters {
            let v = param.value
            if paramValues[param.address] == nil || abs((paramValues[param.address] ?? 0) - v) > parameterChangeThreshold {
                paramValues[param.address] = v
            }
        }
    }
}
