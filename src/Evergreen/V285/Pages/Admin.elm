module Evergreen.V285.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V285.Cloudflare
import Evergreen.V285.Discord
import Evergreen.V285.DmChannel
import Evergreen.V285.Editable
import Evergreen.V285.Id
import Evergreen.V285.LocalState
import Evergreen.V285.NonemptyDict
import Evergreen.V285.Pagination
import Evergreen.V285.Postmark
import Evergreen.V285.SessionIdHash
import Evergreen.V285.Slack
import Evergreen.V285.Table
import Evergreen.V285.ToBackendLog
import Evergreen.V285.User
import Evergreen.V285.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V285.NonemptyDict.NonemptyDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V285.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V285.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V285.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V285.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V285.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V285.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V285.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V285.DmChannel.DmChannelId Evergreen.V285.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) Evergreen.V285.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V285.Pagination.Pagination Evergreen.V285.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash (Evergreen.V285.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V285.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V285.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V285.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash Evergreen.V285.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
        }
    | ExpandSection Evergreen.V285.User.AdminUiSection
    | CollapseSection Evergreen.V285.User.AdminUiSection
    | LogPageChanged (Evergreen.V285.Id.Id Evergreen.V285.Pagination.PageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V285.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V285.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V285.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V285.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V285.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V285.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V285.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V285.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | DeleteGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | RestoreGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | CollapseGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | HideLog (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    | UnhideLog (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    | DisconnectClient Evergreen.V285.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V285.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V285.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
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
    { table : Evergreen.V285.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V285.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V285.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V285.Editable.Model
    , publicVapidKey : Evergreen.V285.Editable.Model
    , privateVapidKey : Evergreen.V285.Editable.Model
    , openRouterKey : Evergreen.V285.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V285.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V285.Editable.Model
    , cloudflareAccountId : Evergreen.V285.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V285.Editable.Model
    , postmarkKey : Evergreen.V285.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V285.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V285.Id.Id Evergreen.V285.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V285.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V285.User.AdminUiSection
    | PressedExpandSection Evergreen.V285.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V285.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V285.Editable.Msg (Maybe Evergreen.V285.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V285.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V285.Editable.Msg Evergreen.V285.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V285.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V285.Editable.Msg (Maybe Evergreen.V285.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V285.Editable.Msg (Maybe Evergreen.V285.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V285.Editable.Msg (Maybe Evergreen.V285.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V285.Editable.Msg (Maybe Evergreen.V285.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V285.Editable.Msg Evergreen.V285.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V285.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V285.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V285.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V285.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V285.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V285.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
