import CoreAudioKit
import SwiftUI
import AVFoundation

/// AUv3 视图控制器 + 工厂
///
/// 同时实现 AUAudioUnitFactory 协议：
/// - 系统实例化此类作为扩展入口（NSExtensionPrincipalClass）
/// - 系统调用 createAudioUnit(with:) 创建音频单元
/// - 视图控制器自动持有音频单元引用，提供 UI
public class EffectViewController: AUViewController, AUAudioUnitFactory {

    var audioUnit: TestEffectAudioUnit?

    // MARK: - AUAudioUnitFactory

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let au = try TestEffectAudioUnit(componentDescription: componentDescription, options: [])
        audioUnit = au
        return au
    }

    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        let effectView = EffectView(getParameterTree: { [weak self] in
            self?.audioUnit?.parameterTree
        })

        let hosting = UIHostingController(rootView: effectView)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        preferredContentSize = CGSize(width: 300, height: 200)
    }
}

// MARK: - SwiftUI 界面

struct EffectView: View {
    let getParameterTree: () -> AUParameterTree?

    @State private var gain: Float = 1.0
    @State private var bypass: Bool = false

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("测试效果器")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("旁通")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $bypass)
                        .onChange(of: bypass) { _, newValue in
                            setParam(address: 1, value: newValue ? 1.0 : 0.0)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("增益")
                        .font(.headline)
                    HStack {
                        Text("0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $gain, in: 0.0...2.0)
                            .onChange(of: gain) { _, newValue in
                                setParam(address: 0, value: newValue)
                            }
                        Text("2.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: "%.2f", gain))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("状态：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("增益 = \(String(format: "%.2f", gain))，旁通 = \(bypass ? "开" : "关")")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .padding()
        .onAppear { pollParameters() }
        .onReceive(timer) { _ in pollParameters() }
    }

    private func pollParameters() {
        guard let tree = getParameterTree() else { return }
        if let p = tree.parameter(withAddress: 0) {
            let v = p.value
            if abs(v - gain) > 0.001 { gain = v }
        }
        if let p = tree.parameter(withAddress: 1) {
            let v = p.value >= 0.5
            if v != bypass { bypass = v }
        }
    }

    private func setParam(address: AUParameterAddress, value: AUValue) {
        guard let tree = getParameterTree(),
              let param = tree.parameter(withAddress: address) else { return }
        param.value = value
    }
}
