module Evergreen.V378.BackendMsgLog exposing (..)

import Effect.Time


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


type alias BackendMsgLogData =
    { backendMsgLog : BackendMsgLog
    , startTime : Effect.Time.Posix
    , endTime : Effect.Time.Posix
    }
