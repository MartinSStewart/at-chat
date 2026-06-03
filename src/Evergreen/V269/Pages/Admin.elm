module Evergreen.V269.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V269.Cloudflare
import Evergreen.V269.Discord
import Evergreen.V269.DmChannel
import Evergreen.V269.Editable
import Evergreen.V269.Id
import Evergreen.V269.LocalState
import Evergreen.V269.NonemptyDict
import Evergreen.V269.Pagination
import Evergreen.V269.Postmark
import Evergreen.V269.SessionIdHash
import Evergreen.V269.Slack
import Evergreen.V269.Table
import Evergreen.V269.ToBackendLog
import Evergreen.V269.User
import Evergreen.V269.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V269.NonemptyDict.NonemptyDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V269.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V269.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V269.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V269.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V269.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V269.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V269.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V269.DmChannel.DmChannelId Evergreen.V269.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) Evergreen.V269.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V269.Pagination.Pagination Evergreen.V269.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash (Evergreen.V269.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V269.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V269.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V269.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash Evergreen.V269.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
        }
    | ExpandSection Evergreen.V269.User.AdminUiSection
    | CollapseSection Evergreen.V269.User.AdminUiSection
    | LogPageChanged (Evergreen.V269.Id.Id Evergreen.V269.Pagination.PageId) (Evergreen.V269.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V269.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V269.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V269.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V269.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V269.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V269.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V269.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V269.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | DeleteGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | RestoreGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | CollapseGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | HideLog (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    | UnhideLog (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    | DisconnectClient Evergreen.V269.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V269.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V269.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
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
    { table : Evergreen.V269.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V269.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V269.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V269.Editable.Model
    , publicVapidKey : Evergreen.V269.Editable.Model
    , privateVapidKey : Evergreen.V269.Editable.Model
    , openRouterKey : Evergreen.V269.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V269.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V269.Editable.Model
    , cloudflareAccountId : Evergreen.V269.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V269.Editable.Model
    , postmarkKey : Evergreen.V269.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V269.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V269.Id.Id Evergreen.V269.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V269.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V269.User.AdminUiSection
    | PressedExpandSection Evergreen.V269.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V269.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V269.Editable.Msg (Maybe Evergreen.V269.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V269.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V269.Editable.Msg Evergreen.V269.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V269.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V269.Editable.Msg (Maybe Evergreen.V269.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V269.Editable.Msg (Maybe Evergreen.V269.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V269.Editable.Msg (Maybe Evergreen.V269.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V269.Editable.Msg (Maybe Evergreen.V269.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V269.Editable.Msg Evergreen.V269.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V269.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V269.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V269.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V269.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V269.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V269.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
