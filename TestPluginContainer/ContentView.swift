import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("测试效果器插件")
                .font(.title)
                .fontWeight(.bold)
            
            Text("此应用包含 TestEffectAUv3 音频单元扩展。")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("安装说明：")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. 运行此应用一次以安装扩展")
                Text("2. 打开 AUv3TestHost 应用")
                Text("3. 点击「刷新插件列表」")
                Text("4. 选择「Effect」类型")
                Text("5. 在列表中找到「Test Effect」")
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
