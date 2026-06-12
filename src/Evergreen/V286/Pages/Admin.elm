module Evergreen.V286.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V286.Cloudflare
import Evergreen.V286.Discord
import Evergreen.V286.DmChannel
import Evergreen.V286.Editable
import Evergreen.V286.Id
import Evergreen.V286.LocalState
import Evergreen.V286.NonemptyDict
import Evergreen.V286.Pagination
import Evergreen.V286.Postmark
import Evergreen.V286.SessionIdHash
import Evergreen.V286.Slack
import Evergreen.V286.Table
import Evergreen.V286.ToBackendLog
import Evergreen.V286.User
import Evergreen.V286.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V286.NonemptyDict.NonemptyDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V286.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V286.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V286.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V286.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V286.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V286.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V286.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V286.DmChannel.DmChannelId Evergreen.V286.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) Evergreen.V286.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V286.Pagination.Pagination Evergreen.V286.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash (Evergreen.V286.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V286.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V286.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V286.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash Evergreen.V286.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
        }
    | ExpandSection Evergreen.V286.User.AdminUiSection
    | CollapseSection Evergreen.V286.User.AdminUiSection
    | LogPageChanged (Evergreen.V286.Id.Id Evergreen.V286.Pagination.PageId) (Evergreen.V286.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V286.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V286.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V286.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V286.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V286.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V286.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V286.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V286.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | DeleteGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | RestoreGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | CollapseGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | HideLog (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    | UnhideLog (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    | DisconnectClient Evergreen.V286.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V286.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V286.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
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
    { table : Evergreen.V286.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V286.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V286.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V286.Editable.Model
    , publicVapidKey : Evergreen.V286.Editable.Model
    , privateVapidKey : Evergreen.V286.Editable.Model
    , openRouterKey : Evergreen.V286.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V286.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V286.Editable.Model
    , cloudflareAccountId : Evergreen.V286.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V286.Editable.Model
    , postmarkKey : Evergreen.V286.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V286.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V286.Id.Id Evergreen.V286.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V286.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V286.User.AdminUiSection
    | PressedExpandSection Evergreen.V286.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V286.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V286.Editable.Msg (Maybe Evergreen.V286.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V286.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V286.Editable.Msg Evergreen.V286.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V286.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V286.Editable.Msg (Maybe Evergreen.V286.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V286.Editable.Msg (Maybe Evergreen.V286.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V286.Editable.Msg (Maybe Evergreen.V286.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V286.Editable.Msg (Maybe Evergreen.V286.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V286.Editable.Msg Evergreen.V286.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V286.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V286.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V286.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V286.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V286.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V286.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
