module Evergreen.V299.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V299.Cloudflare
import Evergreen.V299.Discord
import Evergreen.V299.DmChannel
import Evergreen.V299.Editable
import Evergreen.V299.Id
import Evergreen.V299.LocalState
import Evergreen.V299.NonemptyDict
import Evergreen.V299.Pagination
import Evergreen.V299.Postmark
import Evergreen.V299.SessionIdHash
import Evergreen.V299.Slack
import Evergreen.V299.Table
import Evergreen.V299.ToBackendLog
import Evergreen.V299.User
import Evergreen.V299.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V299.Id.Id Evergreen.V299.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V299.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V299.User.AdminUiSection
    | PressedExpandSection Evergreen.V299.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V299.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V299.Editable.Msg (Maybe Evergreen.V299.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V299.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V299.Editable.Msg Evergreen.V299.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V299.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V299.Editable.Msg (Maybe Evergreen.V299.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V299.Editable.Msg (Maybe Evergreen.V299.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V299.Editable.Msg (Maybe Evergreen.V299.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V299.Editable.Msg (Maybe Evergreen.V299.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V299.Editable.Msg Evergreen.V299.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V299.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V299.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V299.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V299.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V299.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V299.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V299.NonemptyDict.NonemptyDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V299.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V299.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V299.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V299.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V299.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V299.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V299.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V299.DmChannel.DmChannelId Evergreen.V299.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) Evergreen.V299.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V299.Pagination.Pagination Evergreen.V299.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash (Evergreen.V299.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V299.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V299.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V299.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash Evergreen.V299.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
        }
    | ExpandSection Evergreen.V299.User.AdminUiSection
    | CollapseSection Evergreen.V299.User.AdminUiSection
    | LogPageChanged (Evergreen.V299.Id.Id Evergreen.V299.Pagination.PageId) (Evergreen.V299.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V299.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V299.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V299.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V299.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V299.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V299.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V299.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V299.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | DeleteGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | RestoreGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | CollapseGuild (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    | HideLog (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    | UnhideLog (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    | DisconnectClient Evergreen.V299.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V299.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V299.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V299.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V299.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V299.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V299.Editable.Model
    , publicVapidKey : Evergreen.V299.Editable.Model
    , privateVapidKey : Evergreen.V299.Editable.Model
    , openRouterKey : Evergreen.V299.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V299.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V299.Editable.Model
    , cloudflareAccountId : Evergreen.V299.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V299.Editable.Model
    , postmarkKey : Evergreen.V299.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V299.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
