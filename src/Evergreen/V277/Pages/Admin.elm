module Evergreen.V277.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V277.Cloudflare
import Evergreen.V277.Discord
import Evergreen.V277.DmChannel
import Evergreen.V277.Editable
import Evergreen.V277.Id
import Evergreen.V277.LocalState
import Evergreen.V277.NonemptyDict
import Evergreen.V277.Pagination
import Evergreen.V277.Postmark
import Evergreen.V277.SessionIdHash
import Evergreen.V277.Slack
import Evergreen.V277.Table
import Evergreen.V277.ToBackendLog
import Evergreen.V277.User
import Evergreen.V277.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V277.NonemptyDict.NonemptyDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V277.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V277.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V277.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V277.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V277.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V277.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V277.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V277.DmChannel.DmChannelId Evergreen.V277.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) Evergreen.V277.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V277.Pagination.Pagination Evergreen.V277.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash (Evergreen.V277.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V277.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V277.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V277.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash Evergreen.V277.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
        }
    | ExpandSection Evergreen.V277.User.AdminUiSection
    | CollapseSection Evergreen.V277.User.AdminUiSection
    | LogPageChanged (Evergreen.V277.Id.Id Evergreen.V277.Pagination.PageId) (Evergreen.V277.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V277.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V277.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V277.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V277.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V277.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V277.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V277.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V277.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | DeleteGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | RestoreGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | CollapseGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | HideLog (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    | UnhideLog (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    | DisconnectClient Evergreen.V277.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V277.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V277.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
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
    { table : Evergreen.V277.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V277.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V277.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V277.Editable.Model
    , publicVapidKey : Evergreen.V277.Editable.Model
    , privateVapidKey : Evergreen.V277.Editable.Model
    , openRouterKey : Evergreen.V277.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V277.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V277.Editable.Model
    , cloudflareAccountId : Evergreen.V277.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V277.Editable.Model
    , postmarkKey : Evergreen.V277.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V277.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V277.Id.Id Evergreen.V277.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V277.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V277.User.AdminUiSection
    | PressedExpandSection Evergreen.V277.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V277.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V277.Editable.Msg (Maybe Evergreen.V277.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V277.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V277.Editable.Msg Evergreen.V277.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V277.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V277.Editable.Msg (Maybe Evergreen.V277.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V277.Editable.Msg (Maybe Evergreen.V277.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V277.Editable.Msg (Maybe Evergreen.V277.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V277.Editable.Msg (Maybe Evergreen.V277.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V277.Editable.Msg Evergreen.V277.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V277.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V277.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V277.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V277.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V277.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V277.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
