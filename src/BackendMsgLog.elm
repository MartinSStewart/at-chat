module BackendMsgLog exposing (BackendMsgLog(..), BackendMsgLogData, backendMsgLogToString)

import Effect.Time as Time


type alias BackendMsgLogData =
    { backendMsgLog : BackendMsgLog, startTime : Time.Posix, endTime : Time.Posix }


{-| One variant per BackendMsg variant, so that the admin page can show how often each
kind of update runs and how long it takes without holding on to the messages themselves.
-}
type BackendMsgLog
    = BackendMsgLog_SentLoginEmail
    | BackendMsgLog_UserConnected
    | BackendMsgLog_UserDisconnected
    | BackendMsgLog_UserDisconnectedWithTime
    | BackendMsgLog_BackendGotTime
    | BackendMsgLog_SentLogErrorEmail
    | BackendMsgLog_SentNotificationEmail
    | BackendMsgLog_DiscordUserWebsocketMsg
    | BackendMsgLog_SentDiscordGuildMessage
    | BackendMsgLog_SentDiscordDmMessage
    | BackendMsgLog_DeletedDiscordGuildMessage
    | BackendMsgLog_DeletedDiscordDmMessage
    | BackendMsgLog_EditedDiscordGuildMessage
    | BackendMsgLog_EditedDiscordDmMessage
    | BackendMsgLog_DiscordAddedReactionToGuildMessage
    | BackendMsgLog_DiscordAddedReactionToDmMessage
    | BackendMsgLog_DiscordRemovedReactionToGuildMessage
    | BackendMsgLog_DiscordRemovedReactionToDmMessage
    | BackendMsgLog_DiscordTypingIndicatorSent
    | BackendMsgLog_AiChatBackendMsg
    | BackendMsgLog_GotDiscordUserAvatars
    | BackendMsgLog_SentNotification
    | BackendMsgLog_GotVapidKeys
    | BackendMsgLog_GotSlackChannels
    | BackendMsgLog_GotSlackOAuth
    | BackendMsgLog_LinkDiscordUserStep1
    | BackendMsgLog_ReloadDiscordUserStep1
    | BackendMsgLog_HandleReadyDataStep2
    | BackendMsgLog_WebsocketCreatedHandleForUser
    | BackendMsgLog_WebsocketClosedByBackendForUser
    | BackendMsgLog_GatewayReconnectTick
    | BackendMsgLog_WebsocketSentDataForUser
    | BackendMsgLog_DiscordMessageCreate_AttachmentsUploaded
    | BackendMsgLog_DiscordMessageUpdate_AttachmentsUploaded
    | BackendMsgLog_ReloadedDiscordGuildChannel
    | BackendMsgLog_ReloadedDiscordDmChannel
    | BackendMsgLog_ExportBackendStep
    | BackendMsgLog_CountToFrontendStep
    | BackendMsgLog_DownloadBackupChunkStep
    | BackendMsgLog_ScheduledExportBackendStep
    | BackendMsgLog_GotDiscordGuildChannelMessages
    | BackendMsgLog_GotDiscordDmChannelMessages
    | BackendMsgLog_GotTimeForFailedToParseDiscordWebsocket
    | BackendMsgLog_GotTimeForDiscordForumPostRenamed
    | BackendMsgLog_GotGuildMessageEmbed
    | BackendMsgLog_GotDmMessageEmbed
    | BackendMsgLog_DiscordGotGuildMessageEmbed
    | BackendMsgLog_DiscordGotDmMessageEmbed
    | BackendMsgLog_DiscordGotDataForJoinedOrCreatedGuild
    | BackendMsgLog_DiscordGotGuildIcon
    | BackendMsgLog_JoinedDiscordThread
    | BackendMsgLog_ToBackendCompleted
    | BackendMsgLog_GotDiscordReadyDataStickers
    | BackendMsgLog_GotDiscordMessageStickers
    | BackendMsgLog_GotDiscordReadyDataCustomEmojis
    | BackendMsgLog_GotDiscordMessageCustomEmojis
    | BackendMsgLog_HourlyUpdate
    | BackendMsgLog_GotDiscordStandardStickerPacks
    | BackendMsgLog_ScheduledExportUploadResult
    | BackendMsgLog_RegeneratedServerSecret
    | BackendMsgLog_ReloadedDiscordGuildForAdmin
    | BackendMsgLog_GotTimeForWebsocketListenClose
    | BackendMsgLog_Rpc_GotFileUpload
    | BackendMsgLog_GotEnglishWordList
    | BackendMsgLog_GotSwedishWordList
    | BackendMsgLog_Rpc_UserJoinedCall
    | BackendMsgLog_GotTimeForBackendMsg
    | BackendMsgLog_BackendMsgCompleted


backendMsgLogToString : BackendMsgLog -> String
backendMsgLogToString log =
    case log of
        BackendMsgLog_SentLoginEmail ->
            "SentLoginEmail"

        BackendMsgLog_UserConnected ->
            "UserConnected"

        BackendMsgLog_UserDisconnected ->
            "UserDisconnected"

        BackendMsgLog_UserDisconnectedWithTime ->
            "UserDisconnectedWithTime"

        BackendMsgLog_BackendGotTime ->
            "BackendGotTime"

        BackendMsgLog_SentLogErrorEmail ->
            "SentLogErrorEmail"

        BackendMsgLog_SentNotificationEmail ->
            "SentNotificationEmail"

        BackendMsgLog_DiscordUserWebsocketMsg ->
            "DiscordUserWebsocketMsg"

        BackendMsgLog_SentDiscordGuildMessage ->
            "SentDiscordGuildMessage"

        BackendMsgLog_SentDiscordDmMessage ->
            "SentDiscordDmMessage"

        BackendMsgLog_DeletedDiscordGuildMessage ->
            "DeletedDiscordGuildMessage"

        BackendMsgLog_DeletedDiscordDmMessage ->
            "DeletedDiscordDmMessage"

        BackendMsgLog_EditedDiscordGuildMessage ->
            "EditedDiscordGuildMessage"

        BackendMsgLog_EditedDiscordDmMessage ->
            "EditedDiscordDmMessage"

        BackendMsgLog_DiscordAddedReactionToGuildMessage ->
            "DiscordAddedReactionToGuildMessage"

        BackendMsgLog_DiscordAddedReactionToDmMessage ->
            "DiscordAddedReactionToDmMessage"

        BackendMsgLog_DiscordRemovedReactionToGuildMessage ->
            "DiscordRemovedReactionToGuildMessage"

        BackendMsgLog_DiscordRemovedReactionToDmMessage ->
            "DiscordRemovedReactionToDmMessage"

        BackendMsgLog_DiscordTypingIndicatorSent ->
            "DiscordTypingIndicatorSent"

        BackendMsgLog_AiChatBackendMsg ->
            "AiChatBackendMsg"

        BackendMsgLog_GotDiscordUserAvatars ->
            "GotDiscordUserAvatars"

        BackendMsgLog_SentNotification ->
            "SentNotification"

        BackendMsgLog_GotVapidKeys ->
            "GotVapidKeys"

        BackendMsgLog_GotSlackChannels ->
            "GotSlackChannels"

        BackendMsgLog_GotSlackOAuth ->
            "GotSlackOAuth"

        BackendMsgLog_LinkDiscordUserStep1 ->
            "LinkDiscordUserStep1"

        BackendMsgLog_ReloadDiscordUserStep1 ->
            "ReloadDiscordUserStep1"

        BackendMsgLog_HandleReadyDataStep2 ->
            "HandleReadyDataStep2"

        BackendMsgLog_WebsocketCreatedHandleForUser ->
            "WebsocketCreatedHandleForUser"

        BackendMsgLog_WebsocketClosedByBackendForUser ->
            "WebsocketClosedByBackendForUser"

        BackendMsgLog_GatewayReconnectTick ->
            "GatewayReconnectTick"

        BackendMsgLog_WebsocketSentDataForUser ->
            "WebsocketSentDataForUser"

        BackendMsgLog_DiscordMessageCreate_AttachmentsUploaded ->
            "DiscordMessageCreate_AttachmentsUploaded"

        BackendMsgLog_DiscordMessageUpdate_AttachmentsUploaded ->
            "DiscordMessageUpdate_AttachmentsUploaded"

        BackendMsgLog_ReloadedDiscordGuildChannel ->
            "ReloadedDiscordGuildChannel"

        BackendMsgLog_ReloadedDiscordDmChannel ->
            "ReloadedDiscordDmChannel"

        BackendMsgLog_ExportBackendStep ->
            "ExportBackendStep"

        BackendMsgLog_CountToFrontendStep ->
            "CountToFrontendStep"

        BackendMsgLog_DownloadBackupChunkStep ->
            "DownloadBackupChunkStep"

        BackendMsgLog_ScheduledExportBackendStep ->
            "ScheduledExportBackendStep"

        BackendMsgLog_GotDiscordGuildChannelMessages ->
            "GotDiscordGuildChannelMessages"

        BackendMsgLog_GotDiscordDmChannelMessages ->
            "GotDiscordDmChannelMessages"

        BackendMsgLog_GotTimeForFailedToParseDiscordWebsocket ->
            "GotTimeForFailedToParseDiscordWebsocket"

        BackendMsgLog_GotTimeForDiscordForumPostRenamed ->
            "GotTimeForDiscordForumPostRenamed"

        BackendMsgLog_GotGuildMessageEmbed ->
            "GotGuildMessageEmbed"

        BackendMsgLog_GotDmMessageEmbed ->
            "GotDmMessageEmbed"

        BackendMsgLog_DiscordGotGuildMessageEmbed ->
            "DiscordGotGuildMessageEmbed"

        BackendMsgLog_DiscordGotDmMessageEmbed ->
            "DiscordGotDmMessageEmbed"

        BackendMsgLog_DiscordGotDataForJoinedOrCreatedGuild ->
            "DiscordGotDataForJoinedOrCreatedGuild"

        BackendMsgLog_DiscordGotGuildIcon ->
            "DiscordGotGuildIcon"

        BackendMsgLog_JoinedDiscordThread ->
            "JoinedDiscordThread"

        BackendMsgLog_ToBackendCompleted ->
            "ToBackendCompleted"

        BackendMsgLog_GotDiscordReadyDataStickers ->
            "GotDiscordReadyDataStickers"

        BackendMsgLog_GotDiscordMessageStickers ->
            "GotDiscordMessageStickers"

        BackendMsgLog_GotDiscordReadyDataCustomEmojis ->
            "GotDiscordReadyDataCustomEmojis"

        BackendMsgLog_GotDiscordMessageCustomEmojis ->
            "GotDiscordMessageCustomEmojis"

        BackendMsgLog_HourlyUpdate ->
            "HourlyUpdate"

        BackendMsgLog_GotDiscordStandardStickerPacks ->
            "GotDiscordStandardStickerPacks"

        BackendMsgLog_ScheduledExportUploadResult ->
            "ScheduledExportUploadResult"

        BackendMsgLog_RegeneratedServerSecret ->
            "RegeneratedServerSecret"

        BackendMsgLog_ReloadedDiscordGuildForAdmin ->
            "ReloadedDiscordGuildForAdmin"

        BackendMsgLog_GotTimeForWebsocketListenClose ->
            "GotTimeForWebsocketListenClose"

        BackendMsgLog_Rpc_GotFileUpload ->
            "Rpc_GotFileUpload"

        BackendMsgLog_GotEnglishWordList ->
            "GotEnglishWordList"

        BackendMsgLog_GotSwedishWordList ->
            "GotSwedishWordList"

        BackendMsgLog_Rpc_UserJoinedCall ->
            "Rpc_UserJoinedCall"

        BackendMsgLog_GotTimeForBackendMsg ->
            "GotTimeForBackendMsg"

        BackendMsgLog_BackendMsgCompleted ->
            "BackendMsgCompleted"
