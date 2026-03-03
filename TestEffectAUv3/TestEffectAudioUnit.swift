import AVFoundation
import CoreAudioKit
import UIKit
import os

/// AUv3 测试效果器 —— 简单的增益效果
///
/// 设计要点（解决 EXC_BAD_ACCESS 崩溃）：
/// 1. 使用 lazy var 延迟初始化 bus 数组，避免 super.init() 期间隐式解包 nil
/// 2. 使用堆上的 UnsafeMutablePointer<Float> 存储参数值，渲染块仅访问裸指针
/// 3. internalRenderBlock 中不捕获任何 Swift/ObjC 对象，100% 实时安全
public class TestEffectAudioUnit: AUAudioUnit {

    private let log = Logger(subsystem: "com.test.TestEffectAUv3", category: "AudioUnit")

    // MARK: - 音频总线

    private var _inputBus: AUAudioUnitBus
    private var _outputBus: AUAudioUnitBus

    // lazy var：即使 super.init() 内部访问 inputBusses/outputBusses，也能安全初始化
    private lazy var _inputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [_inputBus])
    }()
    private lazy var _outputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [_outputBus])
    }()

    // MARK: - 实时安全的参数存储（堆上裸指针，读写不涉及 ARC / ObjC 消息发送）

    private let _gainPtr: UnsafeMutablePointer<Float>
    private let _bypassPtr: UnsafeMutablePointer<Float>

    // MARK: - 初始化

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        // 1. 堆上分配参数存储
        _gainPtr = .allocate(capacity: 1)
        _gainPtr.initialize(to: 1.0)
        _bypassPtr = .allocate(capacity: 1)
        _bypassPtr.initialize(to: 0.0)

        // 2. 创建总线（在 super.init 之前完成所有 stored property 初始化）
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        _inputBus = try AUAudioUnitBus(format: format)
        _outputBus = try AUAudioUnitBus(format: format)

        // 3. super.init —— 此时若系统查询 inputBusses/outputBusses，lazy var 会安全创建
        try super.init(componentDescription: componentDescription, options: options)

        // 4. 构建参数树
        setupParameterTree()

        log.info("TestEffectAudioUnit 初始化完成")
    }

    deinit {
        _gainPtr.deinitialize(count: 1)
        _gainPtr.deallocate()
        _bypassPtr.deinitialize(count: 1)
        _bypassPtr.deallocate()
    }

    // MARK: - 参数树

    private func setupParameterTree() {
        let gain = AUParameterTree.createParameter(
            withIdentifier: "gain", name: "Gain",
            address: 0,
            min: 0.0, max: 2.0,
            unit: .linearGain, unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil, dependentParameters: nil
        )
        gain.value = 1.0

        let bypass = AUParameterTree.createParameter(
            withIdentifier: "bypass", name: "Bypass",
            address: 1,
            min: 0, max: 1,
            unit: .boolean, unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil, dependentParameters: nil
        )
        bypass.value = 0

        parameterTree = AUParameterTree.createTree(withChildren: [gain, bypass])

        // 观察者通过裸指针更新值 —— 不捕获 self
        let gPtr = _gainPtr
        let bPtr = _bypassPtr

        parameterTree?.implementorValueObserver = { param, value in
            switch param.address {
            case 0: gPtr.pointee = value
            case 1: bPtr.pointee = value
            default: break
            }
        }

        parameterTree?.implementorValueProvider = { param in
            switch param.address {
            case 0: return gPtr.pointee
            case 1: return bPtr.pointee
            default: return 0
            }
        }
    }

    // MARK: - AUAudioUnit 重写

    public override var inputBusses: AUAudioUnitBusArray { _inputBusArray }
    public override var outputBusses: AUAudioUnitBusArray { _outputBusArray }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        log.info("渲染资源已分配")
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        log.info("渲染资源已释放")
    }

    /// 渲染块 —— 100% 实时安全
    /// 仅捕获 UnsafeMutablePointer<Float>（值类型），不涉及 ARC、ObjC 消息发送、锁等
    public override var internalRenderBlock: AUInternalRenderBlock {
        let gPtr = _gainPtr
        let bPtr = _bypassPtr

        return { actionFlags, timestamp, frameCount, outputBusNumber,
                 outputData, realtimeEventListHead, pullInputBlock in

            // 拉取上游音频
            guard let pull = pullInputBlock else { return kAudioUnitErr_NoConnection }
            var flags = AudioUnitRenderActionFlags(rawValue: 0)
            let err = pull(&flags, timestamp, frameCount, 0, outputData)
            guard err == noErr else { return err }

            // 旁通检查（纯内存读取）
            guard bPtr.pointee < 0.5 else { return noErr }

            // 应用增益（纯内存读取 + 浮点运算）
            let gain = gPtr.pointee
            let count = Int(outputData.pointee.mNumberBuffers)
            let bufs  = UnsafeMutableAudioBufferListPointer(outputData)
            for i in 0..<count {
                guard let data = bufs[i].mData else { continue }
                let samples = data.assumingMemoryBound(to: Float.self)
                for f in 0..<Int(frameCount) { samples[f] *= gain }
            }
            return noErr
        }
    }

    // MARK: - 视图控制器（进程内加载时的后备路径）

    public override func requestViewController(completionHandler: @escaping (UIViewController?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completionHandler(nil)
                return
            }
            let vc = EffectViewController()
            vc.audioUnit = self
            completionHandler(vc)
        }
    }
}
