module Evergreen.V323.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V323.Cloudflare
import Evergreen.V323.Discord
import Evergreen.V323.DmChannelId
import Evergreen.V323.Editable
import Evergreen.V323.Id
import Evergreen.V323.LocalState
import Evergreen.V323.NonemptyDict
import Evergreen.V323.Pagination
import Evergreen.V323.Postmark
import Evergreen.V323.SessionIdHash
import Evergreen.V323.Slack
import Evergreen.V323.Table
import Evergreen.V323.ToBackendLog
import Evergreen.V323.User
import Evergreen.V323.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V323.Id.Id Evergreen.V323.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    | PressedExpandSection Evergreen.V323.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    | UserTableMsg Evergreen.V323.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V323.Editable.Msg (Maybe Evergreen.V323.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V323.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V323.Editable.Msg Evergreen.V323.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V323.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V323.Editable.Msg (Maybe Evergreen.V323.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V323.Editable.Msg (Maybe Evergreen.V323.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V323.Editable.Msg (Maybe Evergreen.V323.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V323.Editable.Msg (Maybe Evergreen.V323.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V323.Editable.Msg Evergreen.V323.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V323.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V323.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V323.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V323.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V323.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V323.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V323.NonemptyDict.NonemptyDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V323.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V323.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V323.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V323.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V323.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V323.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V323.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V323.DmChannelId.DmChannelId Evergreen.V323.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V323.Pagination.Pagination Evergreen.V323.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash (Evergreen.V323.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V323.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V323.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V323.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash Evergreen.V323.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V323.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
        }
    | ExpandSection Evergreen.V323.User.AdminUiSection
    | CollapseSection Evergreen.V323.User.AdminUiSection
    | LogPageChanged (Evergreen.V323.Id.Id Evergreen.V323.Pagination.PageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V323.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V323.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V323.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V323.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V323.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V323.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V323.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V323.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | DeleteGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | RestoreGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | CollapseGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | HideLog (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    | UnhideLog (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    | DisconnectClient Evergreen.V323.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V323.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V323.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V323.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V323.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V323.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V323.Editable.Model
    , publicVapidKey : Evergreen.V323.Editable.Model
    , privateVapidKey : Evergreen.V323.Editable.Model
    , openRouterKey : Evergreen.V323.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V323.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V323.Editable.Model
    , cloudflareAccountId : Evergreen.V323.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V323.Editable.Model
    , postmarkKey : Evergreen.V323.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V323.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
