module Evergreen.V275.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V275.Cloudflare
import Evergreen.V275.Discord
import Evergreen.V275.DmChannel
import Evergreen.V275.Editable
import Evergreen.V275.Id
import Evergreen.V275.LocalState
import Evergreen.V275.NonemptyDict
import Evergreen.V275.Pagination
import Evergreen.V275.Postmark
import Evergreen.V275.SessionIdHash
import Evergreen.V275.Slack
import Evergreen.V275.Table
import Evergreen.V275.ToBackendLog
import Evergreen.V275.User
import Evergreen.V275.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V275.NonemptyDict.NonemptyDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V275.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V275.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V275.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V275.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V275.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V275.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V275.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V275.DmChannel.DmChannelId Evergreen.V275.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) Evergreen.V275.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V275.Pagination.Pagination Evergreen.V275.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash (Evergreen.V275.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V275.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V275.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V275.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash Evergreen.V275.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
        }
    | ExpandSection Evergreen.V275.User.AdminUiSection
    | CollapseSection Evergreen.V275.User.AdminUiSection
    | LogPageChanged (Evergreen.V275.Id.Id Evergreen.V275.Pagination.PageId) (Evergreen.V275.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V275.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V275.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V275.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V275.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V275.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V275.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V275.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V275.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | DeleteGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | RestoreGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | CollapseGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | HideLog (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    | UnhideLog (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    | DisconnectClient Evergreen.V275.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V275.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V275.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
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
    { table : Evergreen.V275.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V275.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V275.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V275.Editable.Model
    , publicVapidKey : Evergreen.V275.Editable.Model
    , privateVapidKey : Evergreen.V275.Editable.Model
    , openRouterKey : Evergreen.V275.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V275.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V275.Editable.Model
    , cloudflareAccountId : Evergreen.V275.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V275.Editable.Model
    , postmarkKey : Evergreen.V275.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V275.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V275.Id.Id Evergreen.V275.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V275.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V275.User.AdminUiSection
    | PressedExpandSection Evergreen.V275.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V275.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V275.Editable.Msg (Maybe Evergreen.V275.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V275.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V275.Editable.Msg Evergreen.V275.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V275.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V275.Editable.Msg (Maybe Evergreen.V275.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V275.Editable.Msg (Maybe Evergreen.V275.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V275.Editable.Msg (Maybe Evergreen.V275.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V275.Editable.Msg (Maybe Evergreen.V275.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V275.Editable.Msg Evergreen.V275.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V275.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V275.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V275.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V275.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V275.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V275.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
