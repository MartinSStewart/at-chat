module Evergreen.V266.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V266.Cloudflare
import Evergreen.V266.Discord
import Evergreen.V266.DmChannel
import Evergreen.V266.Editable
import Evergreen.V266.Id
import Evergreen.V266.LocalState
import Evergreen.V266.NonemptyDict
import Evergreen.V266.Pagination
import Evergreen.V266.Postmark
import Evergreen.V266.SessionIdHash
import Evergreen.V266.Slack
import Evergreen.V266.Table
import Evergreen.V266.ToBackendLog
import Evergreen.V266.User
import Evergreen.V266.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V266.NonemptyDict.NonemptyDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V266.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V266.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V266.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V266.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V266.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V266.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V266.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V266.DmChannel.DmChannelId Evergreen.V266.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) Evergreen.V266.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V266.Pagination.Pagination Evergreen.V266.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash (Evergreen.V266.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V266.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V266.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V266.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash Evergreen.V266.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
        }
    | ExpandSection Evergreen.V266.User.AdminUiSection
    | CollapseSection Evergreen.V266.User.AdminUiSection
    | LogPageChanged (Evergreen.V266.Id.Id Evergreen.V266.Pagination.PageId) (Evergreen.V266.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V266.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V266.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V266.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V266.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V266.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V266.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V266.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V266.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | DeleteGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | RestoreGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | CollapseGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | HideLog (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    | UnhideLog (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    | DisconnectClient Evergreen.V266.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V266.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V266.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V266.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V266.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V266.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V266.Editable.Model
    , publicVapidKey : Evergreen.V266.Editable.Model
    , privateVapidKey : Evergreen.V266.Editable.Model
    , openRouterKey : Evergreen.V266.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V266.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V266.Editable.Model
    , cloudflareAccountId : Evergreen.V266.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V266.Editable.Model
    , postmarkKey : Evergreen.V266.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V266.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    , cloudflareEgress : CloudflareEgressStatus
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | CloudflareEgressResponse (Result Effect.Http.Error Int)


type Msg
    = PressedLogPage (Evergreen.V266.Id.Id Evergreen.V266.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V266.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V266.User.AdminUiSection
    | PressedExpandSection Evergreen.V266.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V266.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V266.Editable.Msg (Maybe Evergreen.V266.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V266.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V266.Editable.Msg Evergreen.V266.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V266.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V266.Editable.Msg (Maybe Evergreen.V266.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V266.Editable.Msg (Maybe Evergreen.V266.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V266.Editable.Msg (Maybe Evergreen.V266.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V266.Editable.Msg (Maybe Evergreen.V266.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V266.Editable.Msg Evergreen.V266.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V266.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V266.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V266.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V266.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V266.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V266.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
