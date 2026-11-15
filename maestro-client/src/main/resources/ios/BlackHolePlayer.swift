import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    .init(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
}

func check(_ status: OSStatus, _ operation: String) throws {
    if status != noErr { throw NSError(domain: operation, code: Int(status)) }
}

func blackHoleDevice() throws -> AudioDeviceID {
    let host = AudioObjectID(kAudioObjectSystemObject)
    var selector = address(kAudioHardwarePropertyDevices)
    var bytes: UInt32 = 0
    try check(AudioObjectGetPropertyDataSize(host, &selector, 0, nil, &bytes), "List audio devices")
    var ids = [AudioDeviceID](repeating: 0, count: Int(bytes) / MemoryLayout<AudioDeviceID>.stride)
    try check(AudioObjectGetPropertyData(host, &selector, 0, nil, &bytes, &ids), "Read audio devices")
    for id in ids {
        var nameSelector = address(kAudioObjectPropertyName)
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout.size(ofValue: name))
        let status = AudioObjectGetPropertyData(id, &nameSelector, 0, nil, &size, &name)
        if status == noErr, let name, name.takeRetainedValue() as String == "BlackHole 2ch" {
            return id
        }
    }
    throw NSError(domain: "BlackHole 2ch is not available to Core Audio", code: 1)
}

func play(_ url: URL, requireDefaultInput: Bool) throws {
    var id = try blackHoleDevice()
    if requireDefaultInput {
        var selector = address(kAudioHardwarePropertyDefaultInputDevice)
        var input: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        try check(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &selector, 0, nil, &size, &input), "Read default input")
        guard input == id else {
            throw NSError(domain: "Select BlackHole 2ch as the Simulator sound input", code: 1)
        }
    }
    let file = try AVAudioFile(forReading: url)
    guard file.length > 0 else {
        throw NSError(domain: "macOS speech synthesis returned no audio", code: 1)
    }
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    guard let output = engine.outputNode.audioUnit else { throw NSError(domain: "No HAL output unit", code: 1) }
    let size = UInt32(MemoryLayout.size(ofValue: id))
    try check(AudioUnitSetProperty(output, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &id, size), "Select BlackHole output")
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
    let played = DispatchSemaphore(value: 0)
    player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { _ in played.signal() }
    try engine.start()
    defer { engine.stop() }
    var actual: AudioDeviceID = 0
    var actualSize = size
    try check(AudioUnitGetProperty(output, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &actual, &actualSize), "Verify playback output")
    guard actual == id else { throw NSError(domain: "Unexpected playback output", code: 1) }
    player.play()
    let duration = Double(file.length) / file.processingFormat.sampleRate
    guard played.wait(timeout: .now() + duration + 3) == .success else { throw NSError(domain: "Playback timed out", code: 1) }
    print("Played \(duration) seconds to BlackHole 2ch")
}

do {
    try play(URL(fileURLWithPath: CommandLine.arguments[1]), requireDefaultInput: CommandLine.arguments[2] == "true")
} catch {
    FileHandle.standardError.write(Data("\(error.localizedDescription) [\((error as NSError).domain)]\n".utf8))
    exit(1)
}
