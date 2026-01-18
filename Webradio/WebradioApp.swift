//
//  WebradioApp.swift
//  Webradio
//
//  Created by Michael Hein on 17.01.26.
//

import SwiftUI
import AVFoundation

@main
struct WebradioApp: App {
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
