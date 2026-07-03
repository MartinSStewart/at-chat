module Evergreen.V301.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V301.Cloudflare
import Evergreen.V301.Discord
import Evergreen.V301.DmChannel
import Evergreen.V301.Editable
import Evergreen.V301.Id
import Evergreen.V301.LocalState
import Evergreen.V301.NonemptyDict
import Evergreen.V301.Pagination
import Evergreen.V301.Postmark
import Evergreen.V301.SessionIdHash
import Evergreen.V301.Slack
import Evergreen.V301.Table
import Evergreen.V301.ToBackendLog
import Evergreen.V301.User
import Evergreen.V301.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V301.Id.Id Evergreen.V301.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V301.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V301.User.AdminUiSection
    | PressedExpandSection Evergreen.V301.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V301.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V301.Editable.Msg (Maybe Evergreen.V301.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V301.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V301.Editable.Msg Evergreen.V301.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V301.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V301.Editable.Msg (Maybe Evergreen.V301.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V301.Editable.Msg (Maybe Evergreen.V301.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V301.Editable.Msg (Maybe Evergreen.V301.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V301.Editable.Msg (Maybe Evergreen.V301.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V301.Editable.Msg Evergreen.V301.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V301.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V301.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V301.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V301.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V301.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V301.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V301.NonemptyDict.NonemptyDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V301.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V301.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V301.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V301.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V301.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V301.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V301.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V301.DmChannel.DmChannelId Evergreen.V301.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) Evergreen.V301.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V301.Pagination.Pagination Evergreen.V301.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash (Evergreen.V301.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V301.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V301.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V301.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash Evergreen.V301.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
        }
    | ExpandSection Evergreen.V301.User.AdminUiSection
    | CollapseSection Evergreen.V301.User.AdminUiSection
    | LogPageChanged (Evergreen.V301.Id.Id Evergreen.V301.Pagination.PageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V301.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V301.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V301.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V301.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V301.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V301.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V301.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V301.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | DeleteGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | RestoreGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | CollapseGuild (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId)
    | HideLog (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    | UnhideLog (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    | DisconnectClient Evergreen.V301.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V301.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V301.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V301.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V301.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V301.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V301.Editable.Model
    , publicVapidKey : Evergreen.V301.Editable.Model
    , privateVapidKey : Evergreen.V301.Editable.Model
    , openRouterKey : Evergreen.V301.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V301.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V301.Editable.Model
    , cloudflareAccountId : Evergreen.V301.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V301.Editable.Model
    , postmarkKey : Evergreen.V301.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V301.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
