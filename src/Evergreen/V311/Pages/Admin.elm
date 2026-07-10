module Evergreen.V311.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V311.Cloudflare
import Evergreen.V311.Discord
import Evergreen.V311.DmChannelId
import Evergreen.V311.Editable
import Evergreen.V311.Id
import Evergreen.V311.LocalState
import Evergreen.V311.NonemptyDict
import Evergreen.V311.Pagination
import Evergreen.V311.Postmark
import Evergreen.V311.SessionIdHash
import Evergreen.V311.Slack
import Evergreen.V311.Table
import Evergreen.V311.ToBackendLog
import Evergreen.V311.User
import Evergreen.V311.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V311.Id.Id Evergreen.V311.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V311.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V311.User.AdminUiSection
    | PressedExpandSection Evergreen.V311.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V311.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V311.Editable.Msg (Maybe Evergreen.V311.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V311.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V311.Editable.Msg Evergreen.V311.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V311.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V311.Editable.Msg (Maybe Evergreen.V311.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V311.Editable.Msg (Maybe Evergreen.V311.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V311.Editable.Msg (Maybe Evergreen.V311.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V311.Editable.Msg (Maybe Evergreen.V311.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V311.Editable.Msg Evergreen.V311.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V311.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V311.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V311.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V311.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V311.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V311.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V311.NonemptyDict.NonemptyDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V311.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V311.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V311.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V311.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V311.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V311.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V311.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V311.DmChannelId.DmChannelId Evergreen.V311.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) Evergreen.V311.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V311.Pagination.Pagination Evergreen.V311.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash (Evergreen.V311.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V311.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V311.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V311.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash Evergreen.V311.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V311.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
        }
    | ExpandSection Evergreen.V311.User.AdminUiSection
    | CollapseSection Evergreen.V311.User.AdminUiSection
    | LogPageChanged (Evergreen.V311.Id.Id Evergreen.V311.Pagination.PageId) (Evergreen.V311.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V311.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V311.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V311.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V311.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V311.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V311.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V311.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V311.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | DeleteGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | RestoreGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | CollapseGuild (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    | HideLog (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    | UnhideLog (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    | DisconnectClient Evergreen.V311.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V311.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V311.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V311.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V311.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V311.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V311.Editable.Model
    , publicVapidKey : Evergreen.V311.Editable.Model
    , privateVapidKey : Evergreen.V311.Editable.Model
    , openRouterKey : Evergreen.V311.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V311.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V311.Editable.Model
    , cloudflareAccountId : Evergreen.V311.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V311.Editable.Model
    , postmarkKey : Evergreen.V311.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V311.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
