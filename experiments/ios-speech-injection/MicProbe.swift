import AVFoundation
import UIKit

@main
final class MicProbe: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var recorder: AVAudioRecorder?
    private let audio = AVAudioSession.sharedInstance()
    private let status = UILabel()
    private let start = UIButton(type: .system)
    private let stop = UIButton(type: .system)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        start.setTitle("Start recording", for: .normal)
        start.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        stop.setTitle("Stop recording", for: .normal)
        stop.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        stop.isEnabled = false
        status.text = "Ready"
        let stack = UIStackView(arrangedSubviews: [start, stop, status])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
        ])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        return true
    }

    private var captureURL: URL { URL.documentsDirectory.appendingPathComponent("capture.wav") }

    @objc private func startRecording() {
        do {
            try audio.setCategory(.record, mode: .measurement)
            try audio.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
            ]
            let recorder = try AVAudioRecorder(url: captureURL, settings: settings)
            guard recorder.record() else {
                status.text = "Recorder could not start"
                try? audio.setActive(false)
                return
            }
            self.recorder = recorder
            start.isEnabled = false
            stop.isEnabled = true
            status.text = "Recording"
        } catch {
            status.text = "Recording error: \(error.localizedDescription)"
            try? audio.setActive(false)
        }
    }

    @objc private func stopRecording() {
        recorder?.stop()
        recorder = nil
        try? audio.setActive(false)
        start.isEnabled = true
        stop.isEnabled = false
        do {
            let file = try AVAudioFile(forReading: captureURL)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096) else {
                status.text = "Could not read capture"
                return
            }
            while file.framePosition < file.length {
                try file.read(into: buffer)
                guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { break }
                if UnsafeBufferPointer(start: samples, count: Int(buffer.frameLength)).contains(where: { abs($0) > 0.01 }) {
                    status.text = "Audio captured"
                    return
                }
            }
            status.text = "Silent capture"
        } catch {
            status.text = "Capture error: \(error.localizedDescription)"
        }
    }
}
