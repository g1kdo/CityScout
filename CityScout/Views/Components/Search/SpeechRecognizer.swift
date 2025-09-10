//
//  SpeechRecognizer.swift
//  CityScout
//
//  Created by Umuco Auca on 10/09/2025.
//


import AVFoundation
import Foundation
import Speech
import SwiftUI

class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isListening = false
    @Published var transcriptionText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
        speechRecognizer.delegate = self
        requestAuthorization()
    }

    // Requests speech recognition and microphone permissions from the user
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Must be on the main thread because authorizationStatus is a @Published property
            DispatchQueue.main.async {
                self.authorizationStatus = authStatus
            }
        }
    }

    // Starts the speech recognition process
    func start() throws {
        // Stop any previous task and reset
        recognitionTask?.cancel()
        self.recognitionTask = nil
        self.transcriptionText = ""
        self.errorMessage = nil

        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Set up the recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create a SFSpeechAudioBufferRecognitionRequest object"])
        }
        recognitionRequest.shouldReportPartialResults = true

        // Install the tap on the audio engine's input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                self.transcriptionText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil

                DispatchQueue.main.async {
                    self.isListening = false
                    if let error = error {
                        self.errorMessage = "Speech recognition failed: \(error.localizedDescription)"
                    }
                }
            }
        }

        // Update the listening state
        DispatchQueue.main.async {
            self.isListening = true
        }
    }

    // Stops the speech recognition process
    func stop() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        self.isListening = false
    }

    // Delegate method to check recognizer availability
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            DispatchQueue.main.async {
                self.errorMessage = "Speech recognition is not available on this device or locale."
            }
        }
    }
}
