module Evergreen.V319.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V319.Cloudflare
import Evergreen.V319.Discord
import Evergreen.V319.DmChannelId
import Evergreen.V319.Editable
import Evergreen.V319.Id
import Evergreen.V319.LocalState
import Evergreen.V319.NonemptyDict
import Evergreen.V319.Pagination
import Evergreen.V319.Postmark
import Evergreen.V319.SessionIdHash
import Evergreen.V319.Slack
import Evergreen.V319.Table
import Evergreen.V319.ToBackendLog
import Evergreen.V319.User
import Evergreen.V319.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V319.Id.Id Evergreen.V319.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    | PressedExpandSection Evergreen.V319.User.AdminUiSection
    | PressedEditCell UserTableId UserColumn
    | TypedEditCell String
    | EditCellLostFocus UserTableId UserColumn
    | FocusedOnEditCell
    | EnterKeyInEditCell UserTableId UserColumn
    | PressedSaveUserChanges
    | TabKeyInEditCell Bool
    | PressedResetUserChanges
    | EscapeKeyInEditCell
    | PressedAddUserRow
    | PressedDeleteUser UserTableId
    | PressedResetUser (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | UserTableMsg Evergreen.V319.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V319.Editable.Msg (Maybe Evergreen.V319.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V319.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V319.Editable.Msg Evergreen.V319.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V319.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V319.Editable.Msg (Maybe Evergreen.V319.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V319.Editable.Msg (Maybe Evergreen.V319.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V319.Editable.Msg (Maybe Evergreen.V319.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V319.Editable.Msg (Maybe Evergreen.V319.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V319.Editable.Msg Evergreen.V319.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V319.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V319.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V319.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V319.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V319.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V319.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V319.NonemptyDict.NonemptyDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V319.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V319.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V319.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V319.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V319.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V319.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V319.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V319.DmChannelId.DmChannelId Evergreen.V319.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) Evergreen.V319.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V319.Pagination.Pagination Evergreen.V319.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash (Evergreen.V319.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V319.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V319.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V319.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash Evergreen.V319.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V319.LocalState.WordSpellingGameSwedishStatus
    }


type alias EditedBackendUser =
    { name : String
    , email : String
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }


type AdminChange
    = ChangeUsers
        { time : Effect.Time.Posix
        , changedUsers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
        }
    | ExpandSection Evergreen.V319.User.AdminUiSection
    | CollapseSection Evergreen.V319.User.AdminUiSection
    | LogPageChanged (Evergreen.V319.Id.Id Evergreen.V319.Pagination.PageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V319.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V319.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V319.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V319.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V319.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V319.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V319.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V319.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | DeleteGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | RestoreGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | CollapseGuild (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    | HideLog (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    | UnhideLog (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    | DisconnectClient Evergreen.V319.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V319.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V319.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V319.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type ExportProgress
    = ExportStarting
    | ExportingGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingFinalStep Bytes.Bytes


type alias ExportSubsetSelection =
    { dmChannels : SeqSet.SeqSet Evergreen.V319.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V319.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V319.Editable.Model
    , publicVapidKey : Evergreen.V319.Editable.Model
    , privateVapidKey : Evergreen.V319.Editable.Model
    , openRouterKey : Evergreen.V319.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V319.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V319.Editable.Model
    , cloudflareAccountId : Evergreen.V319.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V319.Editable.Model
    , postmarkKey : Evergreen.V319.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V319.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    , cloudflareEgress : CloudflareEgressStatus
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | CloudflareEgressResponse (Result Effect.Http.Error Int)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
