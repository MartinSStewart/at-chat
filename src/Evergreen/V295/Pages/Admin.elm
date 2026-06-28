module Evergreen.V295.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V295.Cloudflare
import Evergreen.V295.Discord
import Evergreen.V295.DmChannel
import Evergreen.V295.Editable
import Evergreen.V295.Id
import Evergreen.V295.LocalState
import Evergreen.V295.NonemptyDict
import Evergreen.V295.Pagination
import Evergreen.V295.Postmark
import Evergreen.V295.SessionIdHash
import Evergreen.V295.Slack
import Evergreen.V295.Table
import Evergreen.V295.ToBackendLog
import Evergreen.V295.User
import Evergreen.V295.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V295.NonemptyDict.NonemptyDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V295.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V295.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V295.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V295.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V295.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V295.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V295.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V295.DmChannel.DmChannelId Evergreen.V295.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) Evergreen.V295.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V295.Pagination.Pagination Evergreen.V295.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash (Evergreen.V295.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V295.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V295.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V295.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash Evergreen.V295.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
        }
    | ExpandSection Evergreen.V295.User.AdminUiSection
    | CollapseSection Evergreen.V295.User.AdminUiSection
    | LogPageChanged (Evergreen.V295.Id.Id Evergreen.V295.Pagination.PageId) (Evergreen.V295.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V295.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V295.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V295.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V295.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V295.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V295.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V295.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V295.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | DeleteGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | RestoreGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | CollapseGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | HideLog (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    | UnhideLog (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    | DisconnectClient Evergreen.V295.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V295.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V295.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
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
    { table : Evergreen.V295.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V295.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V295.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V295.Editable.Model
    , publicVapidKey : Evergreen.V295.Editable.Model
    , privateVapidKey : Evergreen.V295.Editable.Model
    , openRouterKey : Evergreen.V295.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V295.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V295.Editable.Model
    , cloudflareAccountId : Evergreen.V295.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V295.Editable.Model
    , postmarkKey : Evergreen.V295.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V295.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V295.Id.Id Evergreen.V295.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V295.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V295.User.AdminUiSection
    | PressedExpandSection Evergreen.V295.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V295.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V295.Editable.Msg (Maybe Evergreen.V295.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V295.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V295.Editable.Msg Evergreen.V295.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V295.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V295.Editable.Msg (Maybe Evergreen.V295.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V295.Editable.Msg (Maybe Evergreen.V295.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V295.Editable.Msg (Maybe Evergreen.V295.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V295.Editable.Msg (Maybe Evergreen.V295.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V295.Editable.Msg Evergreen.V295.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V295.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V295.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V295.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V295.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V295.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V295.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
