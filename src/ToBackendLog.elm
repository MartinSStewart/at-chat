module ToBackendLog exposing (ToBackendLog(..), ToBackendLogData, toBackendLogToString)

import Effect.Time as Time
import Id exposing (Id, UserId)


type alias ToBackendLogData =
    { toBackendLog : ToBackendLog, userId : Maybe (Id UserId), startTime : Time.Posix, endTime : Time.Posix }


type ToBackendLog
    = ToBackendLog_CheckLoginRequest
    | ToBackendLog_LoginWithTokenRequest
    | ToBackendLog_LoginWithTwoFactorRequest
    | ToBackendLog_GetLoginTokenRequest
    | ToBackendLog_AdminToBackend
    | ToBackendLog_LogOutRequest
    | ToBackendLog_TwoFactorToBackend
    | ToBackendLog_JoinGuildByInviteRequest
    | ToBackendLog_FinishUserCreationRequest
    | ToBackendLog_AiChatToBackend
    | ToBackendLog_ReloadDataRequest
    | ToBackendLog_LinkSlackOAuthCode
    | ToBackendLog_LinkDiscordRequest
    | ToBackendLog_ProfilePictureEditorToBackend
    | ToBackendLog_AdminDataRequest
    | ToBackendLog_Local_Invalid
    | ToBackendLog_Local_Admin
    | ToBackendLog_Local_SendMessage
    | ToBackendLog_Local_Discord_SendMessage
    | ToBackendLog_Local_NewChannel
    | ToBackendLog_Local_EditChannel
    | ToBackendLog_Local_DeleteChannel
    | ToBackendLog_Local_NewInviteLink
    | ToBackendLog_Local_NewGuild
    | ToBackendLog_Local_MemberTyping
    | ToBackendLog_Local_AddReactionEmoji
    | ToBackendLog_Local_RemoveReactionEmoji
    | ToBackendLog_Local_SendEditMessage
    | ToBackendLog_Local_Discord_SendEditGuildMessage
    | ToBackendLog_Local_Discord_SendEditDmMessage
    | ToBackendLog_Local_MemberEditTyping
    | ToBackendLog_Local_SetLastViewed
    | ToBackendLog_Local_DeleteMessage
    | ToBackendLog_Local_CurrentlyViewing
    | ToBackendLog_Local_SetName
    | ToBackendLog_Local_LoadChannelMessages
    | ToBackendLog_Local_LoadThreadMessages
    | ToBackendLog_Local_Discord_LoadChannelMessages
    | ToBackendLog_Local_Discord_LoadThreadMessages
    | ToBackendLog_Local_SetGuildNotificationLevel
    | ToBackendLog_Local_SetDiscordGuildNotificationLevel
    | ToBackendLog_Local_SetNotificationMode
    | ToBackendLog_Local_RegisterPushSubscription
    | ToBackendLog_Local_TextEditor
    | ToBackendLog_Local_UnlinkDiscordUser
    | ToBackendLog_Local_StartReloadingDiscordUser
    | ToBackendLog_Local_LinkDiscordAcknowledgementIsChecked
    | ToBackendLog_Local_SetDomainWhitelist
    | ToBackendLog_Local_SetEmojiCategory
    | ToBackendLog_Local_SetEmojiSkinTone
    | ToBackendLog_VoiceChatToBackend
    | ToBackendLog_Local_VoiceChatChange


toBackendLogToString : ToBackendLog -> String
toBackendLogToString log =
    case log of
        ToBackendLog_CheckLoginRequest ->
            "CheckLoginRequest"

        ToBackendLog_LoginWithTokenRequest ->
            "LoginWithTokenRequest"

        ToBackendLog_LoginWithTwoFactorRequest ->
            "LoginWithTwoFactorRequest"

        ToBackendLog_GetLoginTokenRequest ->
            "GetLoginTokenRequest"

        ToBackendLog_AdminToBackend ->
            "AdminToBackend"

        ToBackendLog_LogOutRequest ->
            "LogOutRequest"

        ToBackendLog_TwoFactorToBackend ->
            "TwoFactorToBackend"

        ToBackendLog_JoinGuildByInviteRequest ->
            "JoinGuildByInviteRequest"

        ToBackendLog_FinishUserCreationRequest ->
            "FinishUserCreationRequest"

        ToBackendLog_AiChatToBackend ->
            "AiChatToBackend"

        ToBackendLog_ReloadDataRequest ->
            "ReloadDataRequest"

        ToBackendLog_LinkSlackOAuthCode ->
            "LinkSlackOAuthCode"

        ToBackendLog_LinkDiscordRequest ->
            "LinkDiscordRequest"

        ToBackendLog_ProfilePictureEditorToBackend ->
            "ProfilePictureEditorToBackend"

        ToBackendLog_AdminDataRequest ->
            "AdminDataRequest"

        ToBackendLog_Local_Invalid ->
            "Local_Invalid"

        ToBackendLog_Local_Admin ->
            "Local_Admin"

        ToBackendLog_Local_SendMessage ->
            "Local_SendMessage"

        ToBackendLog_Local_Discord_SendMessage ->
            "Local_Discord_SendMessage"

        ToBackendLog_Local_NewChannel ->
            "Local_NewChannel"

        ToBackendLog_Local_EditChannel ->
            "Local_EditChannel"

        ToBackendLog_Local_DeleteChannel ->
            "Local_DeleteChannel"

        ToBackendLog_Local_NewInviteLink ->
            "Local_NewInviteLink"

        ToBackendLog_Local_NewGuild ->
            "Local_NewGuild"

        ToBackendLog_Local_MemberTyping ->
            "Local_MemberTyping"

        ToBackendLog_Local_AddReactionEmoji ->
            "Local_AddReactionEmoji"

        ToBackendLog_Local_RemoveReactionEmoji ->
            "Local_RemoveReactionEmoji"

        ToBackendLog_Local_SendEditMessage ->
            "Local_SendEditMessage"

        ToBackendLog_Local_Discord_SendEditGuildMessage ->
            "Local_Discord_SendEditGuildMessage"

        ToBackendLog_Local_Discord_SendEditDmMessage ->
            "Local_Discord_SendEditDmMessage"

        ToBackendLog_Local_MemberEditTyping ->
            "Local_MemberEditTyping"

        ToBackendLog_Local_SetLastViewed ->
            "Local_SetLastViewed"

        ToBackendLog_Local_DeleteMessage ->
            "Local_DeleteMessage"

        ToBackendLog_Local_CurrentlyViewing ->
            "Local_CurrentlyViewing"

        ToBackendLog_Local_SetName ->
            "Local_SetName"

        ToBackendLog_Local_LoadChannelMessages ->
            "Local_LoadChannelMessages"

        ToBackendLog_Local_LoadThreadMessages ->
            "Local_LoadThreadMessages"

        ToBackendLog_Local_Discord_LoadChannelMessages ->
            "Local_Discord_LoadChannelMessages"

        ToBackendLog_Local_Discord_LoadThreadMessages ->
            "Local_Discord_LoadThreadMessages"

        ToBackendLog_Local_SetGuildNotificationLevel ->
            "Local_SetGuildNotificationLevel"

        ToBackendLog_Local_SetDiscordGuildNotificationLevel ->
            "Local_SetDiscordGuildNotificationLevel"

        ToBackendLog_Local_SetNotificationMode ->
            "Local_SetNotificationMode"

        ToBackendLog_Local_RegisterPushSubscription ->
            "Local_RegisterPushSubscription"

        ToBackendLog_Local_TextEditor ->
            "Local_TextEditor"

        ToBackendLog_Local_UnlinkDiscordUser ->
            "Local_UnlinkDiscordUser"

        ToBackendLog_Local_StartReloadingDiscordUser ->
            "Local_StartReloadingDiscordUser"

        ToBackendLog_Local_LinkDiscordAcknowledgementIsChecked ->
            "Local_LinkDiscordAcknowledgementIsChecked"

        ToBackendLog_Local_SetDomainWhitelist ->
            "Local_SetDomainWhitelist"

        ToBackendLog_Local_SetEmojiCategory ->
            "Local_SetEmojiCategory"

        ToBackendLog_Local_SetEmojiSkinTone ->
            "Local_SetEmojiSkinTone"

        ToBackendLog_VoiceChatToBackend ->
            "VoiceChatToBackend"

        ToBackendLog_Local_VoiceChatChange ->
            "Local_VoiceChatChange"
