//
//  PlayerController.swift
//  Caster
//
//  Created by Alex Truong on 5/20/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

enum PlayerStatus: Int {
    case inactive
    case connecting
    case readyToPlay
    case failed
    case unknown
}

enum PlayerMode: Int {
    case buffering
    case pause
    case wait
    case playing
    case end
}

protocol PlayerControllerDelegate: class {
    
    func playerController(_ sender: PlayerController, didChangeRateTo rate: Double)
    
    func playerController(_ sender: PlayerController, didUpdateProgress progress: Int)
    
    func playerController(_ sender: PlayerController, didUpdateBufferDuration duration: Int)

    func playerController(_ sender: PlayerController, didChangePlayerStatusTo status: PlayerStatus)

    func playerController(_ sender: PlayerController, didChangePlayerModeTo mode: PlayerMode)
    
    func didPlayToEnd(_ sender: PlayerController)
    
    func playerController(_ sender: PlayerController, didEncounterUnexpectedError error: String)
}

class PlayerController: NSObject {
    
    var delegate: PlayerControllerDelegate?
    
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var asset: AVAsset?
    var hasVideo: Bool = false
    
    var duration: Int = 0
    var bufferDuration: Int = 0
    var progress: Int = 0
    
    var status = PlayerStatus.inactive
    var mode = PlayerMode.pause
    
    var podcast: PodcastEntry?
    var episode: EpisodeItem?
    var artwork: UIImage?
    var artist: String = "Unknown Artist"
    var mediaItemArtwork: MPMediaItemArtwork?
    
    deinit {
        deallocObservers()
    }
    
    func deallocObservers() {
        if let playerItem = self.playerItem {
            player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
            
            NotificationCenter.default.removeObserver(self)
            
            self.player?.replaceCurrentItem(with: nil)
            self.playerItem = nil
            self.asset = nil
        }
    }

    func abandonCurrentPlayerItem() {
        // stop current player item
        self.player?.pause()
        deallocObservers()
    }
    
    // start player with an URL
    func startPlayer(forEpisode episode: EpisodeItem?, inPodcast podcast: PodcastEntry?, withArtwork artwork: UIImage?) {
        
        self.episode = episode
        self.podcast = podcast
        self.artwork = artwork
        
        self.mediaItemArtwork = MPMediaItemArtwork(boundsSize: CGSize(width: 400, height: 400)) { size in
            return self.artwork!
        }

        if let author = episode?.author {
            artist = author
        } else if let partist = podcast?.artist {
            artist = partist
        } else if let pauthor = podcast?.author {
            artist = pauthor
        }
        
        // reset info
        status = .unknown
        duration = 1
        progress = 0
        bufferDuration = 0
        hasVideo = false
        nowPlayingRate = 0.0
        
        updateNowPlayingBarMediaInfo()
        
        var url = episode?.enclosureUrl
        if (url ?? "").isEmpty {
            url = episode?.mediaUrl
        }
        
        if (url ?? "").isEmpty {
            let error = "Unable to play: media url is empty"
            DispatchQueue.main.async {
                nowPlayingArtist.text = error
            }
            self.delegate?.playerController(self, didEncounterUnexpectedError: error)
            
            return
        }

        DispatchQueue.global(qos: .background).async {
            if let url = url, let mediaUrl = URL(string: url) {
                self.status = .connecting
                self.updateNowPlayingBarMode()
                self.delegate?.playerController(self, didChangePlayerStatusTo: self.status)
                
                let assetKeys = [
                    "playable",
                    "hasProtectedContent"
                ]
                
                // new asset
                self.asset = AVAsset(url: mediaUrl)
                
                // create player item
                self.playerItem = AVPlayerItem(asset: self.asset!, automaticallyLoadedAssetKeys: assetKeys)
                self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
                // preferred 5 mins pre-bufferred
                self.playerItem?.preferredForwardBufferDuration = 300.0
                
                // create new player if nil
                if self.player == nil {
                    self.player = AVPlayer()
                    self.player?.actionAtItemEnd = .pause
                    self.player?.automaticallyWaitsToMinimizeStalling = true

                    // enable background play
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                    } catch {}
                }
                self.player?.replaceCurrentItem(with: self.playerItem)
                
                // observe this player item if everything is set
                if let player = self.player, let playerItem = self.playerItem {
                    // observe buffering
                    playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: NSKeyValueObservingOptions(), context: nil)
                    
                    // observe status
                    playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)

                    // observe time control status
                    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new], context: nil)
                    
                    // observe progress time
                    // 1 times per second
                    player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.global(qos: .background), using: self.progressObserver)
                    
                    // observe when this item is finished
                    NotificationCenter.default.addObserver(self, selector: #selector(PlayerController.playerItemDidPlayToEnd(_:)), name: NSNotification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification"), object: player.currentItem)
                    
                }
            }
        }
    }
    
    // progress observer
    func progressObserver(_ time: CMTime) {
        let secs = CMTimeGetSeconds(time)
        if !secs.isNaN, !secs.isInfinite {
            self.progress = Int(secs)
            updateNowPlayingInfoCenter()
            updateNowPlayingBarProgress()
            self.delegate?.playerController(self, didUpdateProgress: self.progress)
        }
    }
    
    // end of item notification
    func playerItemDidPlayToEnd(_ notification: Notification) {
        player?.seek(to: kCMTimeZero)
        player?.pause()

        self.progress = 0
        self.mode = .end
        
        self.delegate?.playerController(self, didChangePlayerModeTo: self.mode)
        self.delegate?.didPlayToEnd(self)
    }
    
    // KVO func
    func playerStatusChanged(newStatus: AVPlayerItemStatus) {
        switch newStatus {
            
        case .readyToPlay:
            if self.status == .connecting {
                let time = CMTimeGetSeconds((playerItem?.asset.duration)!)
                if !time.isNaN, !time.isInfinite {
                    self.duration = Int(time)
                } else {
                    // TODO: which value?
                    self.duration = 1
                }
                
                if let count = self.asset?.tracks(withMediaType: AVMediaTypeVideo).count {
                    self.hasVideo = (count > 0)
                }
                self.status = .readyToPlay
                self.mode = .buffering
                self.updateNowPlayingBarMode()
                self.delegate?.playerController(self, didChangePlayerStatusTo: self.status)
                self.delegate?.playerController(self, didChangePlayerModeTo: self.mode)
            }
            
        case .failed:
            self.status = .failed
            self.updateNowPlayingBarMode()
            self.delegate?.playerController(self, didChangePlayerStatusTo: self.status)

            
        case .unknown:
            self.status = .unknown
            self.updateNowPlayingBarMode()
            self.delegate?.playerController(self, didChangePlayerStatusTo: self.status)
            
        }
    }
    
    // KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // buffering
        if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            if let playerItem = self.playerItem {
                let values = playerItem.loadedTimeRanges.map({ $0.timeRangeValue})
                if let timeRange = values.first {
                    let duration = CMTimeGetSeconds(timeRange.duration)
                    if !duration.isNaN, !duration.isInfinite {
                        self.bufferDuration = Int(duration)
                        
                        // play immediately if buffer duration exceeds 1 min
                        if self.bufferDuration > 60, self.mode == .buffering {
                            self.playImmediately(atRate: 1.0)
                        }
                        
                        self.delegate?.playerController(self, didUpdateBufferDuration: self.bufferDuration)
                    }
                }
            }
        } else
            
        // player status
        if keyPath == #keyPath(AVPlayerItem.status) {
            // Get the status change from the change dictionary
            if let newNumber = change?[.newKey] as? NSNumber {
                if let newStatus = AVPlayerItemStatus(rawValue: newNumber.intValue) {
                    playerStatusChanged(newStatus: newStatus)
                }
            }
        } else
        
        // AVPlayer.timeControlStatus
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if let newNumber = change?[.newKey] as? NSNumber {
                if let newStatus = AVPlayerTimeControlStatus(rawValue: newNumber.intValue) {
                    
                    switch (newStatus) {
                    
                    case .paused:
                        self.mode = .pause
                        
                    case .waitingToPlayAtSpecifiedRate:
                        self.mode = .wait
                        
                    case .playing:
                        self.mode = .playing
                    }

                    self.updateNowPlayingBarMode()
                    self.delegate?.playerController(self, didChangePlayerModeTo: self.mode)
                }
            }
        }
    }
    
    // MARK: -
    
    func toggleNowPlaying(sender: Any?) {
        if let playerItem = self.playerItem {
            let rate = CMTimebaseGetRate(playerItem.timebase!)
            if rate == 0 {
                playImmediately(atRate: 1.0)
            } else {
                pause()
            }
        }
    }
    
    func playImmediately(atRate rate: Float) {
        if let player = self.player, self.status == .readyToPlay || self.mode == .end {
            player.playImmediately(atRate: rate)
        }
    }
    
    func pause() {
        if let player = self.player, self.status == .readyToPlay {
            player.pause()
        }
    }
    
    func skipBackward() {
        if let player = self.player, self.status == .readyToPlay {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            if !currentTime.isNaN, !currentTime.isInfinite {
                var time: Int = Int(currentTime) - 30
                
                if time < 0 {
                    time = 0
                }
                
                player.seek(to: CMTimeMake(Int64(time), 1))
            }
        }
    }
    
    func skipForward() {
        if let player = self.player, self.status == .readyToPlay {
            let currentTime = CMTimeGetSeconds(player.currentTime())
                if !currentTime.isNaN, !currentTime.isInfinite {

                var time: Int = Int(currentTime) + 30
                
                if time > self.duration {
                    time = self.duration
                }
                
                player.seek(to: CMTimeMake(Int64(time), 1))
            }
        }
    }
    
    func updateNowPlayingBarMediaInfo() {
        // this is weird but smaller size makes it looks better (more crispy)
        if let id = podcast?.id, let artworkThumb = Utility.loadSmallArtworkFromFile(withId: id) {
            DispatchQueue.main.async {
                nowPlayingBackground.image = artworkThumb
                nowPlayingArtwork.image = artworkThumb
            }
        } else if let artwork = self.artwork {
            DispatchQueue.main.async {
                nowPlayingBackground.image = artwork
                nowPlayingArtwork.image = artwork
            }
        }
        
        DispatchQueue.main.async {
            nowPlayingTitle.text = self.episode?.title ?? "Unknown Title"
            nowPlayingArtist.text = self.artist
        }
    }
    
    func updateNowPlayingBarProgress() {
        if let playerItem = self.playerItem, let timebase = playerItem.timebase {
            let rate = CMTimebaseGetRate(timebase)

            // progress
            DispatchQueue.main.async {
                nowPlayingProgress.progress = Float(self.progress)/Float(self.duration)
            }
            
            // play/pause button
            if rate != nowPlayingRate {
                DispatchQueue.main.async {
                    nowPlayingButton.setImage(rate > 0 ? nowPauseImage : nowPlayImage, for: .normal)
                }
                nowPlayingRate = rate
                self.delegate?.playerController(self, didChangeRateTo: rate)
            }
        }
    }
    
    func updateNowPlayingBarMode() {
        updateNowPlayingBarProgress()
        
        switch (self.status) {
            
        case .connecting:
            DispatchQueue.main.async {
                nowPlayingArtist.text = "Connecting..."
            }
            
        case .readyToPlay:
            switch (self.mode) {
                
            case .buffering:
                DispatchQueue.main.async {
                    nowPlayingArtist.text = "Buffering..."
                }
                
            case .wait:
                DispatchQueue.main.async {
                    nowPlayingArtist.text = "Buffering..."
                }
                
            default:
                DispatchQueue.main.async {
                    nowPlayingArtist.text = self.artist
                }
            }
            
        case .failed, .unknown:
            DispatchQueue.main.async {
                nowPlayingArtist.text = "Error: " + (mediaPlayer.playerItem?.error?.localizedDescription ?? "")
            }
            
        default:
            DispatchQueue.main.async {
                nowPlayingArtist.text = self.artist
            }
        }
    }

    func updateNowPlayingInfoCenter() {
        var rate: Double = 0
        
        if let playerItem = self.playerItem, let timebase = playerItem.timebase {
            rate = CMTimebaseGetRate(timebase)
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: episode?.title ?? "Unknown episode",
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyArtwork: mediaItemArtwork!,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: self.progress,
            MPMediaItemPropertyPlaybackDuration: self.duration,
            MPNowPlayingInfoPropertyPlaybackRate: rate,
        ]
    }
}
