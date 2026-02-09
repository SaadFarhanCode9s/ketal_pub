//
// ManualMocks.swift
// Mocks that are missing from GeneratedMocks.swift due to environment issues.
//

import AnalyticsEvents
import Combine
import Compound
import Foundation
import LocalAuthentication
import MatrixRustSDK
import UIKit
import UserNotifications

// MARK: - AppLockServiceMock

class AppLockServiceMock: AppLockServiceProtocol {
    var isMandatory = false
    var isEnabled = false
    var isEnabledPublisher: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher()
    var biometryType: LABiometryType = .none
    var biometricUnlockEnabled = false
    var biometricUnlockTrusted = false
    
    var numberOfPINAttempts: AnyPublisher<Int, Never> = Just(0).eraseToAnyPublisher()
    
    // Configurable properties for tests
    var underlyingBiometryType: LABiometryType = .none
    var underlyingBiometricUnlockEnabled = false
    var unlockWithClosure: ((String) -> Bool)?
    
    // Removed duplicate `static func mock(...)` method here because it's already defined
    // in AppLockServiceProtocol.swift via an extension on AppLockServiceMock.
    
    func setupPINCode(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        .success(())
    }
    
    func validate(_ pinCode: String) -> Result<Void, AppLockServiceError> {
        .success(())
    }
    
    func enableBiometricUnlock() -> Result<Void, AppLockServiceError> {
        .success(())
    }
    
    func disableBiometricUnlock() { }
    
    func disable() { }
    
    func applicationDidEnterBackground() { }
    
    func computeNeedsUnlock(didBecomeActiveAt date: Date) -> Bool {
        false
    }
    
    func unlock(with pinCode: String) -> Bool {
        unlockWithClosure?(pinCode) ?? true
    }
    
    func unlockWithBiometrics() async -> AppLockServiceBiometricResult {
        .unlocked
    }
}

// MARK: - NetworkMonitorMock

class NetworkMonitorMock: NetworkMonitorProtocol {
    var reachabilityPublisher: CurrentValuePublisher<NetworkMonitorReachability, Never> =
        CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable).asCurrentValuePublisher()
    
    /// `underlyingReachabilityPublisher` is needed for the extension in NetworkMonitorMock.swift to work
    var underlyingReachabilityPublisher: CurrentValueSubject<NetworkMonitorReachability, Never> = .init(.reachable)
}

// MARK: - PollInteractionHandlerMock

class PollInteractionHandlerMock: PollInteractionHandlerProtocol {
    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        .success(())
    }
    
    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        .success(())
    }
}

// MARK: - WindowManagerMock

class WindowManagerMock: WindowManagerProtocol {
    var mainWindow: UIWindow! = UIWindow()
    var overlayWindow: UIWindow! = UIWindow()
    var globalSearchWindow: UIWindow! = UIWindow()
    var alternateWindow: UIWindow! = UIWindow()
    
    var windows: [UIWindow] {
        [mainWindow, overlayWindow, globalSearchWindow, alternateWindow]
    }
    
    func showGlobalSearch() { }
    func hideGlobalSearch() { }
    
    // OrientationManagerProtocol
    func setOrientation(_ orientation: UIInterfaceOrientationMask) { }
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) { }
}

// MARK: - AnalyticsClientMock

class AnalyticsClientMock: AnalyticsClientProtocol {
    var isRunning = false
    
    func start(analyticsConfiguration: AnalyticsConfiguration) { }
    
    func capture(_ event: AnalyticsEventProtocol) { }
    
    func screen(_ event: AnalyticsScreenProtocol) { }
    
    func updateUserProperties(_ event: AnalyticsEvent.UserProperties) { }
    
    func reset() { }
    
    func stop() { }
}

// MARK: - VoiceMessageMediaManagerMock

class VoiceMessageMediaManagerMock: VoiceMessageMediaManagerProtocol {
    func loadVoiceMessageFromSource(_ source: MediaSourceProxy, body: String?) async throws -> URL {
        URL(fileURLWithPath: "/dev/null")
    }
}

// MARK: - RoomPreviewProxyMock

class RoomPreviewProxyMock: RoomPreviewProxyProtocol {
    var info: RoomPreviewInfoProxy {
        get { underlyingInfo }
        set { underlyingInfo = newValue }
    }

    var underlyingInfo: RoomPreviewInfoProxy!
    
    var underlyingOwnMembershipDetails: RoomMembershipDetailsProxyProtocol?
    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? {
        get async { underlyingOwnMembershipDetails }
    }
    
    init() { }
}

// MARK: - MediaPlayerProviderMock

class MediaPlayerProviderMock: MediaPlayerProviderProtocol {
    var player: AudioPlayerProtocol {
        // Return a dummy player or a mock if available
        // Assuming AudioPlayerMock exists or using a dummy
        AudioPlayerMock()
    }
    
    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState? {
        nil
    }
    
    func register(audioPlayerState: AudioPlayerState) { }
    
    func unregister(audioPlayerState: AudioPlayerState) { }
    
    func detachAllStates(except exception: AudioPlayerState?) async { }
}

/// Helper AudioPlayerMock if not likely generated
class AudioPlayerMock: AudioPlayerProtocol {
    var state: MediaPlayerState {
        .stopped
    }

    var sourceURL: URL? {
        nil
    }

    var playbackURL: URL? {
        nil
    }

    var currentTime: TimeInterval {
        0
    }

    var duration: TimeInterval {
        0
    }

    var actions: AnyPublisher<AudioPlayerAction, Never> {
        Just(.didStopPlaying).eraseToAnyPublisher()
    }
    
    func load(sourceURL: URL, playbackURL: URL, autoplay: Bool) { }
    func play() { }
    func pause() { }
    func stop() { }
    func reset() { }
    func seek(to progress: Double) async { }
}

// MARK: - TimelineControllerFactoryMock

class TimelineControllerFactoryMock: TimelineControllerFactoryProtocol {
    struct Configuration {
        var timelineController: TimelineControllerProtocol?
        var threadTimelineController: TimelineControllerProtocol?
    }

    convenience init(_ configuration: Configuration) {
        self.init()

        buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue = configuration.timelineController ?? {
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            return timelineController
        }()

        buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure = { threadRootEventID, _, _, _, _ in
            if let threadTimelineController = configuration.threadTimelineController {
                return .success(threadTimelineController)
            } else {
                let timelineController = MockTimelineController(timelineKind: .thread(rootEventID: threadRootEventID))
                timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
                return .success(timelineController)
            }
        }
    }
    
    // MARK: - Spies
    
    var buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue: TimelineControllerProtocol?
    var buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure: ((String, String?, JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?
    var buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure: ((JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?
    var buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure: ((TimelineFocus, [TimelineAllowedMessageType], TimelineKind.MediaPresentation, JoinedRoomProxyProtocol, RoomTimelineItemFactoryProtocol, MediaProviderProtocol) -> Result<TimelineControllerProtocol, TimelineFactoryControllerError>)?

    // MARK: - Implementation
    
    func buildTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                 initialFocussedEventID: String?,
                                 timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                 mediaProvider: MediaProviderProtocol) -> TimelineControllerProtocol {
        if let returnValue = buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReturnValue {
            return returnValue
        }
        return MockTimelineController()
    }
    
    func buildThreadTimelineController(threadRootEventID: String,
                                       initialFocussedEventID: String?,
                                       roomProxy: JoinedRoomProxyProtocol,
                                       timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                       mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        if let closure = buildThreadTimelineControllerThreadRootEventIDInitialFocussedEventIDRoomProxyTimelineItemFactoryMediaProviderClosure {
            return closure(threadRootEventID, initialFocussedEventID, roomProxy, timelineItemFactory, mediaProvider)
        }
        return .success(MockTimelineController())
    }
    
    func buildPinnedEventsTimelineController(roomProxy: JoinedRoomProxyProtocol,
                                             timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                             mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        if let closure = buildPinnedEventsTimelineControllerRoomProxyTimelineItemFactoryMediaProviderClosure {
            return closure(roomProxy, timelineItemFactory, mediaProvider)
        }
        return .success(MockTimelineController())
    }
    
    func buildMessageFilteredTimelineController(focus: TimelineFocus,
                                                allowedMessageTypes: [TimelineAllowedMessageType],
                                                presentation: TimelineKind.MediaPresentation,
                                                roomProxy: JoinedRoomProxyProtocol,
                                                timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                                mediaProvider: MediaProviderProtocol) async -> Result<TimelineControllerProtocol, TimelineFactoryControllerError> {
        if let closure = buildMessageFilteredTimelineControllerFocusAllowedMessageTypesPresentationRoomProxyTimelineItemFactoryMediaProviderClosure {
            return closure(focus, allowedMessageTypes, presentation, roomProxy, timelineItemFactory, mediaProvider)
        }
        return .success(MockTimelineController())
    }
}

// MARK: - UserNotificationCenterMock

class UserNotificationCenterMock: UserNotificationCenterProtocol {
    var delegate: UNUserNotificationCenterDelegate?
    var authorizationStatusReturnValue: UNAuthorizationStatus = .authorized

    func add(_ request: UNNotificationRequest) async throws { }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func deliveredNotifications() async -> [UNNotification] {
        []
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) { }
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) { }
    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusReturnValue
    }

    func notificationSettings() async -> UNNotificationSettings {
        fatalError("Mock not implemented")
    }
}

// MARK: - TimelineItemProviderMock

class TimelineItemProviderMock: TimelineItemProviderProtocol {
    var updatePublisher: AnyPublisher<([TimelineItemProxy], PaginationState), Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    let _updatePublisher = PassthroughSubject<([TimelineItemProxy], PaginationState), Never>()

    var itemProxies: [TimelineItemProxy] = []
    var paginationState: PaginationState = .initial
    var kind: TimelineKind = .live

    var membershipChangePublisher: AnyPublisher<Void, Never> {
        underlyingMembershipChangePublisher ?? Empty().eraseToAnyPublisher()
    }

    var underlyingMembershipChangePublisher: AnyPublisher<Void, Never>?
}

// MARK: - TimelineProxyMock

class TimelineProxyMock: TimelineProxyProtocol {
    var timelineItemProvider: TimelineItemProviderProtocol {
        if let underlyingTimelineItemProvider {
            return underlyingTimelineItemProvider
        }
        fatalError("underlyingTimelineItemProvider not set")
    }

    var underlyingTimelineItemProvider: TimelineItemProviderProtocol?
    
    // Spies
    var sendMessageEventContentReturnValue: Result<Void, TimelineProxyError>?
    var paginateBackwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>?
    var paginateForwardsRequestSizeReturnValue: Result<Void, TimelineProxyError>?
    var sendReadReceiptForTypeReturnValue: Result<Void, TimelineProxyError>?
    var createPollQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>?
    var editPollOriginalQuestionAnswersPollKindReturnValue: Result<Void, TimelineProxyError>?

    func subscribeForUpdates() async { }
    func fetchDetails(for eventID: String) { }
    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        nil
    }

    func retryDecryption(sessionIDs: [String]?) { }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateBackwardsRequestSizeReturnValue ?? .success(())
    }

    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineProxyError> {
        paginateForwardsRequestSizeReturnValue ?? .success(())
    }
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, newContent: EditedContent) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID, reason: String?) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func pin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        .success(true)
    }

    func unpin(eventID: String) async -> Result<Bool, TimelineProxyError> {
        .success(true)
    }
    
    func sendAudio(url: URL, audioInfo: AudioInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func sendFile(url: URL, fileInfo: FileInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func sendImage(url: URL, thumbnailURL: URL, imageInfo: ImageInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func sendLocation(body: String, geoURI: GeoURI, description: String?, zoomLevel: UInt8?, assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func sendVideo(url: URL, thumbnailURL: URL, videoInfo: VideoInfo, caption: String?, requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func sendVoiceMessage(url: URL, audioInfo: AudioInfo, waveform: [Float], requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        .success(())
    }
    
    func sendReadReceipt(for eventID: String, type: ReceiptType) async -> Result<Void, TimelineProxyError> {
        sendReadReceiptForTypeReturnValue ?? .success(())
    }

    func markAsRead(receiptType: ReceiptType) async -> Result<Void, TimelineProxyError> {
        .success(())
    }
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        sendMessageEventContentReturnValue ?? .success(())
    }
    
    func sendMessage(_ message: String, html: String?, inReplyToEventID: String?, intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func toggleReaction(_ reaction: String, to eventID: TimelineItemIdentifier.EventOrTransactionID) async -> Result<Void, TimelineProxyError> {
        .success(())
    }
    
    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        createPollQuestionAnswersPollKindReturnValue ?? .success(())
    }
    
    func editPoll(original eventID: String, question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        editPollOriginalQuestionAnswersPollKindReturnValue ?? .success(())
    }
    
    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        .success(())
    }

    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        .success(())
    }
    
    func getLoadedReplyDetails(eventID: String) async -> Result<InReplyToDetails, TimelineProxyError> {
        .failure(.failedRedacting)
    }
    
    func buildMessageContentFor(_ message: String, html: String?, intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        .init(noHandle: .init())
    }
}
