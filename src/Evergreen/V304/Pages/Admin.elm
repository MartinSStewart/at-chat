module Evergreen.V304.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V304.Cloudflare
import Evergreen.V304.Discord
import Evergreen.V304.DmChannelId
import Evergreen.V304.Editable
import Evergreen.V304.Id
import Evergreen.V304.LocalState
import Evergreen.V304.NonemptyDict
import Evergreen.V304.Pagination
import Evergreen.V304.Postmark
import Evergreen.V304.SessionIdHash
import Evergreen.V304.Slack
import Evergreen.V304.Table
import Evergreen.V304.ToBackendLog
import Evergreen.V304.User
import Evergreen.V304.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V304.Id.Id Evergreen.V304.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V304.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V304.User.AdminUiSection
    | PressedExpandSection Evergreen.V304.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V304.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V304.Editable.Msg (Maybe Evergreen.V304.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V304.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V304.Editable.Msg Evergreen.V304.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V304.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V304.Editable.Msg (Maybe Evergreen.V304.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V304.Editable.Msg (Maybe Evergreen.V304.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V304.Editable.Msg (Maybe Evergreen.V304.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V304.Editable.Msg (Maybe Evergreen.V304.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V304.Editable.Msg Evergreen.V304.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V304.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V304.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V304.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V304.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V304.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V304.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V304.NonemptyDict.NonemptyDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V304.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V304.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V304.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V304.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V304.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V304.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V304.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V304.DmChannelId.DmChannelId Evergreen.V304.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) Evergreen.V304.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V304.Pagination.Pagination Evergreen.V304.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash (Evergreen.V304.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V304.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V304.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V304.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash Evergreen.V304.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
        }
    | ExpandSection Evergreen.V304.User.AdminUiSection
    | CollapseSection Evergreen.V304.User.AdminUiSection
    | LogPageChanged (Evergreen.V304.Id.Id Evergreen.V304.Pagination.PageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V304.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V304.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V304.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V304.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V304.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V304.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V304.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V304.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | DeleteGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | RestoreGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | CollapseGuild (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    | HideLog (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    | UnhideLog (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    | DisconnectClient Evergreen.V304.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V304.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V304.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V304.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V304.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V304.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V304.Editable.Model
    , publicVapidKey : Evergreen.V304.Editable.Model
    , privateVapidKey : Evergreen.V304.Editable.Model
    , openRouterKey : Evergreen.V304.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V304.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V304.Editable.Model
    , cloudflareAccountId : Evergreen.V304.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V304.Editable.Model
    , postmarkKey : Evergreen.V304.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V304.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
