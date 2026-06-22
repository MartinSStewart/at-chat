module Evergreen.V294.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V294.Cloudflare
import Evergreen.V294.Discord
import Evergreen.V294.DmChannel
import Evergreen.V294.Editable
import Evergreen.V294.Id
import Evergreen.V294.LocalState
import Evergreen.V294.NonemptyDict
import Evergreen.V294.Pagination
import Evergreen.V294.Postmark
import Evergreen.V294.SessionIdHash
import Evergreen.V294.Slack
import Evergreen.V294.Table
import Evergreen.V294.ToBackendLog
import Evergreen.V294.User
import Evergreen.V294.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V294.NonemptyDict.NonemptyDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V294.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V294.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V294.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V294.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V294.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V294.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V294.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V294.DmChannel.DmChannelId Evergreen.V294.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) Evergreen.V294.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V294.Pagination.Pagination Evergreen.V294.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash (Evergreen.V294.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V294.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V294.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V294.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash Evergreen.V294.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
        }
    | ExpandSection Evergreen.V294.User.AdminUiSection
    | CollapseSection Evergreen.V294.User.AdminUiSection
    | LogPageChanged (Evergreen.V294.Id.Id Evergreen.V294.Pagination.PageId) (Evergreen.V294.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V294.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V294.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V294.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V294.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V294.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V294.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V294.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V294.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | DeleteGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | RestoreGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | CollapseGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | HideLog (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    | UnhideLog (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    | DisconnectClient Evergreen.V294.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V294.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V294.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
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
    { table : Evergreen.V294.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V294.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V294.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V294.Editable.Model
    , publicVapidKey : Evergreen.V294.Editable.Model
    , privateVapidKey : Evergreen.V294.Editable.Model
    , openRouterKey : Evergreen.V294.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V294.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V294.Editable.Model
    , cloudflareAccountId : Evergreen.V294.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V294.Editable.Model
    , postmarkKey : Evergreen.V294.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V294.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V294.Id.Id Evergreen.V294.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V294.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V294.User.AdminUiSection
    | PressedExpandSection Evergreen.V294.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V294.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V294.Editable.Msg (Maybe Evergreen.V294.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V294.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V294.Editable.Msg Evergreen.V294.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V294.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V294.Editable.Msg (Maybe Evergreen.V294.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V294.Editable.Msg (Maybe Evergreen.V294.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V294.Editable.Msg (Maybe Evergreen.V294.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V294.Editable.Msg (Maybe Evergreen.V294.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V294.Editable.Msg Evergreen.V294.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V294.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V294.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V294.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V294.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V294.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V294.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
