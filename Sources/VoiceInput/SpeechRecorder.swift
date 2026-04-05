import Foundation
import AVFoundation
import Speech

class SpeechRecorder: NSObject {
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var onResult: (String, Bool) -> Void
    var onRMSUpdate: ((Double) -> Void)?
    
    private var latestText = ""
    private var stopCompletion: ((String) -> Void)?
    private var isRecording = false
    
    init(onResult: @escaping (String, Bool) -> Void) {
        self.onResult = onResult
        super.init()
    }
    
    func startRecording(locale: String) {
        NSLog("[VoiceInput] SpeechRecorder.startRecording for locale: \(locale)")
        
        cleanup()
        latestText = ""
        isRecording = true
        
        let localeObj = Locale(identifier: locale)
        speechRecognizer = SFSpeechRecognizer(locale: localeObj)
        
        guard let recognizer = speechRecognizer else {
            NSLog("[VoiceInput] Speech recognizer not available for locale: \(locale)")
            return
        }
        
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true
        
        guard let audioEngine = audioEngine, let request = recognitionRequest else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, self.isRecording else { return }
            self.recognitionRequest?.append(buffer)
            let rms = self.calculateRMS(buffer)
            DispatchQueue.main.async {
                self.onRMSUpdate?(rms)
            }
        }
        
        NSLog("[VoiceInput] Audio tap installed, format: \(recordingFormat)")
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            NSLog("[VoiceInput] Audio engine started")
        } catch {
            NSLog("[VoiceInput] Audio engine start error: \(error)")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self, self.isRecording else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                self.latestText = text
                
                self.onResult(text, isFinal)
                
                if isFinal {
                    self.stopCompletion?(text)
                    self.stopCompletion = nil
                }
            }
            
            if let error = error {
                NSLog("[VoiceInput] Recognition error: \(error.localizedDescription)")
                self.stopCompletion?(self.latestText)
                self.stopCompletion = nil
            }
        }
        
        NSLog("[VoiceInput] Recognition task started (on-device)")
    }
    
    func stopRecording(completion: @escaping (String) -> Void) {
        NSLog("[VoiceInput] SpeechRecorder.stopRecording, latestText: '\(latestText)'")
        
        isRecording = false
        stopCompletion = completion
        
        // 结束音频输入
        recognitionRequest?.endAudio()
        
        // 立即返回当前最新文本，不等待最终结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.stopCompletion != nil {
                NSLog("[VoiceInput] stopRecording returning: '\(self.latestText)'")
                self.stopCompletion?(self.latestText)
                self.stopCompletion = nil
                self.cleanupAudioOnly()
            }
        }
    }
    
    private func cleanupAudioOnly() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
    }
    
    private func cleanup() {
        isRecording = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
    }
    
    private func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let val = channelDataValue[i]
            sum += val * val
        }
        let rms = sqrt(sum / Float(frameLength))
        return min(Double(rms) * 5.0, 1.0)
    }
}
