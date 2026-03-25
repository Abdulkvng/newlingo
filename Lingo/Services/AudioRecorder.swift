import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var volume: CGFloat = 0
    @Published var error: String?

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    override init() {
        super.init()
    }

    func startRecording() {
        error = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            self.error = "Failed to set up audio session."
            return
        }

        // Check microphone permission
        switch AVAudioApplication.shared.recordPermission {
        case .denied:
            self.error = "Microphone access denied. Please enable it in Settings."
            return
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecording()
                    } else {
                        self?.error = "Microphone access is required to record."
                    }
                }
            }
            return
        case .granted:
            beginRecording()
        @unknown default:
            break
        }
    }

    private func beginRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "lingo_recording_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true

            // Volume metering
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateVolume()
            }
        } catch {
            self.error = "Failed to start recording."
        }
    }

    private func updateVolume() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()

        // Convert dB to linear scale (0-1)
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = max(0, (level + 60) / 60) // -60dB to 0dB -> 0 to 1
        DispatchQueue.main.async {
            self.volume = CGFloat(normalizedLevel)
        }
    }

    func stopRecording() -> Data? {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        isRecording = false
        volume = 0

        guard let url = recordingURL else { return nil }
        defer {
            // Clean up temp file
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }

        return try? Data(contentsOf: url)
    }

    func cancelRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        isRecording = false
        volume = 0

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }

    deinit {
        cancelRecording()
    }
}
