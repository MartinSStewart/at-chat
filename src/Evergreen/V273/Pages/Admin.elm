module Evergreen.V273.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V273.Cloudflare
import Evergreen.V273.Discord
import Evergreen.V273.DmChannel
import Evergreen.V273.Editable
import Evergreen.V273.Id
import Evergreen.V273.LocalState
import Evergreen.V273.NonemptyDict
import Evergreen.V273.Pagination
import Evergreen.V273.Postmark
import Evergreen.V273.SessionIdHash
import Evergreen.V273.Slack
import Evergreen.V273.Table
import Evergreen.V273.ToBackendLog
import Evergreen.V273.User
import Evergreen.V273.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V273.NonemptyDict.NonemptyDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V273.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V273.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V273.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V273.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V273.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V273.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V273.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V273.DmChannel.DmChannelId Evergreen.V273.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) Evergreen.V273.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V273.Pagination.Pagination Evergreen.V273.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash (Evergreen.V273.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V273.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V273.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V273.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash Evergreen.V273.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
        }
    | ExpandSection Evergreen.V273.User.AdminUiSection
    | CollapseSection Evergreen.V273.User.AdminUiSection
    | LogPageChanged (Evergreen.V273.Id.Id Evergreen.V273.Pagination.PageId) (Evergreen.V273.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V273.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V273.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V273.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V273.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V273.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V273.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V273.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V273.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | DeleteGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | RestoreGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | CollapseGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | HideLog (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    | UnhideLog (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    | DisconnectClient Evergreen.V273.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V273.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V273.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
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
    { table : Evergreen.V273.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V273.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V273.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V273.Editable.Model
    , publicVapidKey : Evergreen.V273.Editable.Model
    , privateVapidKey : Evergreen.V273.Editable.Model
    , openRouterKey : Evergreen.V273.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V273.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V273.Editable.Model
    , cloudflareAccountId : Evergreen.V273.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V273.Editable.Model
    , postmarkKey : Evergreen.V273.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V273.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V273.Id.Id Evergreen.V273.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V273.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V273.User.AdminUiSection
    | PressedExpandSection Evergreen.V273.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V273.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V273.Editable.Msg (Maybe Evergreen.V273.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V273.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V273.Editable.Msg Evergreen.V273.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V273.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V273.Editable.Msg (Maybe Evergreen.V273.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V273.Editable.Msg (Maybe Evergreen.V273.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V273.Editable.Msg (Maybe Evergreen.V273.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V273.Editable.Msg (Maybe Evergreen.V273.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V273.Editable.Msg Evergreen.V273.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V273.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V273.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V273.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V273.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V273.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V273.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
