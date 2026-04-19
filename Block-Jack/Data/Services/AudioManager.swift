//
//  AudioManager.swift
//  Block-Jack
//

import AVFoundation
import Foundation

enum SoundEffect: String {
    case blockPlace = "sfx_place"
    case lineClear = "sfx_clear"
    case flush = "sfx_flush"
    case bossEntry = "sfx_boss_intro"
    case roundWin = "sfx_victory"
    case gameOver = "sfx_gameover"
    case perkUnlock = "sfx_unlock"
    case buttonTap = "sfx_tap"
    case coin = "sfx_coin"
}

enum MusicTrack: String {
    case menu = "bgm_menu"
    case battle = "bgm_battle"
    case boss = "bgm_boss"
}

class AudioManager {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    
    var isSoundEnabled: Bool {
        UserEnvironment.shared.isSoundEnabled
    }
    
    private init() {
        // Prepare audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
    }
    
    // MARK: - BGM Logic
    
    func playMusic(_ track: MusicTrack) {
        guard isSoundEnabled else { return }
        
        // Don't restart if already playing the same track
        if bgmPlayer?.url?.lastPathComponent.contains(track.rawValue) == true && bgmPlayer?.isPlaying == true {
            return
        }
        
        stopMusic()
        
        // Try m4a first, then mp3
        guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "m4a") ??
                        Bundle.main.url(forResource: track.rawValue, withExtension: "mp3") else {
            print("Music file not found: \(track.rawValue)")
            return
        }
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // Endless loop
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            bgmPlayer?.volume = 0.5
        } catch {
            print("Could not play music: \(error)")
        }
    }
    
    func stopMusic() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
    func setMusicIntensity(streak: Int) {
        guard let player = bgmPlayer, isSoundEnabled else { return }
        
        // Dynamic intensity based on streak
        // Increase volume and speed slightly
        let volumeBoost = min(0.4, Double(streak) * 0.05) // max +0.4
        let speedBoost = min(0.15, Double(streak) * 0.02)  // max +0.15 speed
        
        player.volume = 0.5 + Float(volumeBoost)
        player.enableRate = true
        player.rate = 1.0 + Float(speedBoost)
    }
    
    // MARK: - SFX Logic
    
    func playSFX(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Use a new player each time to allow overlapping sounds
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "m4a") ??
                        Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") ?? 
                        Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            
            // Optional: Store reference to prevent deallocation mid-play if needed
            // But usually for short SFX, the player instance needs to stay alive.
            // A simple way is to use a pool or just fire and forget if the block keeps it alive.
            // In SwiftUI/ARC, fire and forget might stop early. Let's keep a small pool.
            let key = UUID().uuidString
            sfxPlayers[key] = player
            
            // Clean up after it's done
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                self.sfxPlayers.removeValue(forKey: key)
            }
        } catch {
            print("Could not play SFX: \(error)")
        }
    }
}
