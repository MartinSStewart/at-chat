module Evergreen.V298.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V298.Cloudflare
import Evergreen.V298.Discord
import Evergreen.V298.DmChannel
import Evergreen.V298.Editable
import Evergreen.V298.Id
import Evergreen.V298.LocalState
import Evergreen.V298.NonemptyDict
import Evergreen.V298.Pagination
import Evergreen.V298.Postmark
import Evergreen.V298.SessionIdHash
import Evergreen.V298.Slack
import Evergreen.V298.Table
import Evergreen.V298.ToBackendLog
import Evergreen.V298.User
import Evergreen.V298.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V298.Id.Id Evergreen.V298.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V298.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V298.User.AdminUiSection
    | PressedExpandSection Evergreen.V298.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V298.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V298.Editable.Msg (Maybe Evergreen.V298.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V298.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V298.Editable.Msg Evergreen.V298.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V298.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V298.Editable.Msg (Maybe Evergreen.V298.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V298.Editable.Msg (Maybe Evergreen.V298.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V298.Editable.Msg (Maybe Evergreen.V298.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V298.Editable.Msg (Maybe Evergreen.V298.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V298.Editable.Msg Evergreen.V298.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V298.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V298.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V298.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V298.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V298.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V298.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V298.NonemptyDict.NonemptyDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V298.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V298.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V298.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V298.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V298.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V298.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V298.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V298.DmChannel.DmChannelId Evergreen.V298.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Evergreen.V298.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) Evergreen.V298.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V298.Pagination.Pagination Evergreen.V298.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V298.SessionIdHash.SessionIdHash (Evergreen.V298.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V298.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V298.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V298.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V298.SessionIdHash.SessionIdHash Evergreen.V298.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
        }
    | ExpandSection Evergreen.V298.User.AdminUiSection
    | CollapseSection Evergreen.V298.User.AdminUiSection
    | LogPageChanged (Evergreen.V298.Id.Id Evergreen.V298.Pagination.PageId) (Evergreen.V298.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V298.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V298.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V298.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V298.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V298.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V298.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V298.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V298.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | DeleteGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | RestoreGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | CollapseGuild (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    | HideLog (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    | UnhideLog (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    | DisconnectClient Evergreen.V298.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V298.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V298.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V298.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V298.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V298.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V298.Editable.Model
    , publicVapidKey : Evergreen.V298.Editable.Model
    , privateVapidKey : Evergreen.V298.Editable.Model
    , openRouterKey : Evergreen.V298.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V298.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V298.Editable.Model
    , cloudflareAccountId : Evergreen.V298.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V298.Editable.Model
    , postmarkKey : Evergreen.V298.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V298.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
