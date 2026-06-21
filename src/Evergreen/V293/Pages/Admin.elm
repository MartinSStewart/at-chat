module Evergreen.V293.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V293.Cloudflare
import Evergreen.V293.Discord
import Evergreen.V293.DmChannel
import Evergreen.V293.Editable
import Evergreen.V293.Id
import Evergreen.V293.LocalState
import Evergreen.V293.NonemptyDict
import Evergreen.V293.Pagination
import Evergreen.V293.Postmark
import Evergreen.V293.SessionIdHash
import Evergreen.V293.Slack
import Evergreen.V293.Table
import Evergreen.V293.ToBackendLog
import Evergreen.V293.User
import Evergreen.V293.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V293.NonemptyDict.NonemptyDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V293.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V293.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V293.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V293.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V293.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V293.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V293.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V293.DmChannel.DmChannelId Evergreen.V293.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) Evergreen.V293.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V293.Pagination.Pagination Evergreen.V293.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash (Evergreen.V293.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V293.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V293.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V293.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash Evergreen.V293.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
        }
    | ExpandSection Evergreen.V293.User.AdminUiSection
    | CollapseSection Evergreen.V293.User.AdminUiSection
    | LogPageChanged (Evergreen.V293.Id.Id Evergreen.V293.Pagination.PageId) (Evergreen.V293.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V293.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V293.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V293.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V293.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V293.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V293.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V293.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V293.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | DeleteGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | RestoreGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | CollapseGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | HideLog (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    | UnhideLog (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    | DisconnectClient Evergreen.V293.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V293.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V293.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
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
    { table : Evergreen.V293.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V293.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V293.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V293.Editable.Model
    , publicVapidKey : Evergreen.V293.Editable.Model
    , privateVapidKey : Evergreen.V293.Editable.Model
    , openRouterKey : Evergreen.V293.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V293.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V293.Editable.Model
    , cloudflareAccountId : Evergreen.V293.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V293.Editable.Model
    , postmarkKey : Evergreen.V293.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V293.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V293.Id.Id Evergreen.V293.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V293.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V293.User.AdminUiSection
    | PressedExpandSection Evergreen.V293.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V293.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V293.Editable.Msg (Maybe Evergreen.V293.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V293.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V293.Editable.Msg Evergreen.V293.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V293.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V293.Editable.Msg (Maybe Evergreen.V293.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V293.Editable.Msg (Maybe Evergreen.V293.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V293.Editable.Msg (Maybe Evergreen.V293.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V293.Editable.Msg (Maybe Evergreen.V293.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V293.Editable.Msg Evergreen.V293.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V293.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V293.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V293.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V293.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V293.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V293.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
