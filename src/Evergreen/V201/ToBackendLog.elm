module Evergreen.V201.ToBackendLog exposing (..)

import Effect.Time
import Evergreen.V201.Id


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


type alias ToBackendLogData =
    { toBackendLog : ToBackendLog
    , userId : Maybe (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    , startTime : Effect.Time.Posix
    , endTime : Effect.Time.Posix
    }
