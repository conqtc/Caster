//
//  NowPlayingViewController.swift
//  Caster
//
//  Created by Alex Truong on 4/27/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import UserNotifications

protocol NowPlayingDelegate: class {
    func didDismissNowPlaying(_ sender: NowPlayingViewController)
}

class NowPlayingViewController: UIViewController {
    var delegate: NowPlayingDelegate?
    
    var artwork: UIImage?
    var currentEpisode: EpisodeItem?
    var currentPodcast: PodcastEntry?
    
    @IBOutlet weak var infoView: UIView!
    var artworkViewController: NowPlayingArtworkViewController?
    var episodeViewController: NowPlayingEpisodeViewController?
    var currentViewController: UIViewController?
    var pendingViewController: UIViewController?
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var backgroundImageView: UIImageView!
    var pageController: UIPageViewController!

    @IBOutlet weak var trackSlider: CustomSlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var bufferProgress: UIProgressView!
    @IBOutlet weak var totalLabel: UILabel!
    
    var attributedText: NSMutableAttributedString?
    
    let playImage = UIImage(named: "Play")
    let pauseImage = UIImage(named: "Pause")
    var isDragging = false
    var shouldStartPlay = true
    var didCancelInteractive = false
    
    /*
    override var prefersStatusBarHidden: Bool {
        return true
    }
    */
    
    // interactive pull down
    lazy var slideInTransitioningDelegate = SlideInTransitioningDelegate(direction: .bottom, animation: .animationSpringWithDamping)
    var interactiveTransition = UIPercentDrivenInteractiveTransition()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // custom transition
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = slideInTransitioningDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.modalPresentationCapturesStatusBarAppearance = true
        
        // just to display current now playing item
        if currentEpisode == nil {
            artwork = mediaPlayer.artwork
            currentEpisode = mediaPlayer.episode
            currentPodcast = mediaPlayer.podcast
            shouldStartPlay = false
        }

        // set background image to current artwork
        backgroundImageView.image = artwork

        // setup page controls
        setupPageControl()
        
        if !shouldStartPlay {
            // update progress and duration (in case of ie. pause)
            totalLabel.text = Utility.timeFormatFromSeconds(mediaPlayer.duration)
            bufferProgress.progress = Float(mediaPlayer.bufferDuration)/Float(mediaPlayer.duration)
            progressLabel.text = Utility.timeFormatFromSeconds(mediaPlayer.progress)
            trackSlider.value = Float(mediaPlayer.progress)/Float(mediaPlayer.duration)
            updatePlayInfo()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // do not call this again when interactive is cancelled
        if !didCancelInteractive {
            // register delegate
            mediaPlayer.delegate = self
            
            if shouldStartPlay {
                // start a playing for this episode
                startPlay()
            } else {
                topupVideoLayerIfNeeded()
            }

            // setup pan for the pull down
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDismissNowPlaying(self)
        
        // remove delegate
        mediaPlayer.delegate = nil
    }
    
    func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let translate = gesture.translation(in: gesture.view)
        let percent = translate.y / gesture.view!.bounds.size.height
        
        switch gesture.state {
            
        case .began:
            slideInTransitioningDelegate.interactiveTransition = interactiveTransition
            dismiss(animated: true)
            
        case .changed:
            interactiveTransition.update(percent)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: gesture.view)
            
            if (percent > 0.5 && velocity.y == 0) || velocity.y > 0 {
                interactiveTransition.finish()
            } else {
                didCancelInteractive = true
                interactiveTransition.cancel()
            }
            
            slideInTransitioningDelegate.interactiveTransition = nil
            
        default:
            break
        }
    }

    func topupVideoLayerIfNeeded() {
        // for video player
        if mediaPlayer.hasVideo {
            DispatchQueue.main.async {
                let videoView = UIView(frame: (self.artworkViewController?.artworkImageView.frame)!)
                
                let layer = AVPlayerLayer(player: mediaPlayer.player)
                layer.zPosition = 1.0
                layer.frame = videoView.bounds
                videoView.layer.addSublayer(layer)
                
                if let view = self.artworkViewController?.view {
                    // dim the artwork
                    videoView.alpha = 0
                    view.addSubview(videoView)

                    UIView.animate(withDuration: 1.0, animations: {
                        self.artworkViewController?.artworkImageView.alpha = 0.05
                        videoView.alpha = 1.0
                    }) { completed in
                    }
                }
            }
        }
    }
    
    func setupPageControl() {
        // setup page controller
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "NowPlayingArtwork") as? NowPlayingArtworkViewController {
            self.artworkViewController = viewController
            artworkViewController?.artwork = self.artwork
            artworkViewController?.episodeTitle = currentEpisode?.title
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "NowPlayingEpisode") as? NowPlayingEpisodeViewController {
            self.episodeViewController = viewController
            prepareEpisodeInfo()
        }
        
        pageController.setViewControllers([self.artworkViewController!], direction: .forward, animated: true, completion: nil)
        currentViewController = self.artworkViewController
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        
        pageController.view.frame = infoView.bounds
        infoView.addSubview(pageController.view)
    }
    
    @IBAction func progressTouchDown(_ sender: Any) {
        isDragging = true
    }
    
    @IBAction func progressTouchUpInside(_ sender: UISlider) {
        if let player = mediaPlayer.player {
            let newPos = Float(mediaPlayer.duration) * sender.value
            player.seek(to: CMTimeMake(Int64(newPos), 1)) { completed in
                self.isDragging = false
            }
        } else {
            self.isDragging = false
        }
    }
    
    @IBAction func progressTouchCancel(_ sender: Any) {
        isDragging = false
    }
    
    @IBAction func progressDragInside(_ sender: UISlider) {
        if mediaPlayer.playerItem != nil {
            let newPos = Float(mediaPlayer.duration) * sender.value
            self.progressLabel.text = Utility.timeFormatFromSeconds(Int(newPos))
        }
    }

    @IBAction func doneTouched(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func backwardTouched(_ sender: UIButton) {
        mediaPlayer.skipBackward()
    }
    
    @IBAction func forwardTouched(_ sender: UIButton) {
        mediaPlayer.skipForward()
    }
    
    func startPlay() {
        mediaPlayer.startPlayer(forEpisode: currentEpisode, inPodcast: currentPodcast, withArtwork: artwork)
    }
    
    @IBAction func playTouched(_ sender: UIButton) {
        mediaPlayer.toggleNowPlaying(sender: nil)
    }
}

// MARK: - handling media player controller
extension NowPlayingViewController: PlayerControllerDelegate {
    
    func playerController(_ sender: PlayerController, didChangeRateTo rate: Double) {
        DispatchQueue.main.async {
            self.playButton.setImage(rate > 0 ? self.pauseImage : self.playImage, for: .normal)
        }
    }
    
    func playerController(_ sender: PlayerController, didEncounterUnexpectedError error: String) {
        DispatchQueue.main.async {
            self.progressLabel.text = error
        }
    }
    
    func playerController(_ sender: PlayerController, didChangePlayerModeTo mode: PlayerMode) {
        self.updatePlayInfo()
    }
    
    func playerController(_ sender: PlayerController, didChangePlayerStatusTo status: PlayerStatus) {
        if status == .readyToPlay {
            DispatchQueue.main.async {
                self.totalLabel.text = Utility.timeFormatFromSeconds(mediaPlayer.duration)
            }
            self.topupVideoLayerIfNeeded()
        }
        
        self.updatePlayInfo()
    }
    
    func playerController(_ sender: PlayerController, didUpdateProgress progress: Int) {
        if progress > 0 {
            if !self.isDragging {
                DispatchQueue.main.async {
                    self.progressLabel.text = Utility.timeFormatFromSeconds(progress)
                    self.trackSlider.value = Float(progress)/Float(mediaPlayer.duration)
                }
            }
            self.updatePlayInfo()
        }

    }
    
    func playerController(_ sender: PlayerController, didUpdateBufferDuration duration: Int) {
        // update buffer progress
        DispatchQueue.main.async {
            self.bufferProgress.progress = Float(duration)/Float(mediaPlayer.duration)
        }
    }

    func didPlayToEnd(_ sender: PlayerController) {
        self.updatePlayInfo()
    }
    
    // update button image
    func updatePlayInfo() {
        if let playerItem = mediaPlayer.playerItem, let timebase = playerItem.timebase {
            let rate = CMTimebaseGetRate(timebase)
            DispatchQueue.main.async {
                self.playButton.setImage(rate > 0 ? self.pauseImage : self.playImage, for: .normal)
            }
        }
        
        switch (mediaPlayer.status) {
        case .connecting:
            DispatchQueue.main.async {
                self.progressLabel.text = "Connecting..."
            }
            
        case .readyToPlay:
            switch (mediaPlayer.mode) {
                
            case .buffering:
                DispatchQueue.main.async {
                    self.progressLabel.text = "Buffering..."
                }
                
            default:
                break
            }
            
        case .failed:
            DispatchQueue.main.async {
                self.progressLabel.text = "Failed: " + (mediaPlayer.playerItem?.error?.localizedDescription ?? "")
            }
            
        case .unknown:
            DispatchQueue.main.async {
                self.progressLabel.text = "Unknown: " + (mediaPlayer.playerItem?.error?.localizedDescription ?? "")
            }
            
        default:
            break
            
        }
    }
    
}

// MARK: - prepare attributed string for episode information
extension NowPlayingViewController {
    // prepare attributed string for episode's information
    func prepareEpisodeInfo() {
        // reuse if already has
        if let attributedText = attributedText {
            self.episodeViewController?.attributedText = attributedText
            
            return
        }
        
        DataFetcher.fetchEpisodeAttributedString(episode: self.currentEpisode) { attributedText in
            self.attributedText = attributedText
            self.episodeViewController?.attributedText = attributedText
        }
    }
}

// MARK: - page view controller delegate
extension NowPlayingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingViewController = pendingViewControllers.first
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            currentViewController = pendingViewController
            if let _ = currentViewController as? NowPlayingArtworkViewController {
                pageControl.currentPage = 0
            } else {
                pageControl.currentPage = 1
            }
        }
    }
}

// MARK: - page view controller data source
extension NowPlayingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let _ = currentViewController as? NowPlayingArtworkViewController {
            return nil
        } else {
            return self.artworkViewController
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let _ = currentViewController as? NowPlayingArtworkViewController {
            return self.episodeViewController
        } else {
            return nil
        }
    }
}

// MARK: - prevent our gesture from interferring with UISlider
extension NowPlayingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isKind(of: UISlider.self) ?? false) {
            return false
        }
        
        return true
    }
}
