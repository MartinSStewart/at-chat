module Evergreen.V289.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V289.Cloudflare
import Evergreen.V289.Discord
import Evergreen.V289.DmChannel
import Evergreen.V289.Editable
import Evergreen.V289.Id
import Evergreen.V289.LocalState
import Evergreen.V289.NonemptyDict
import Evergreen.V289.Pagination
import Evergreen.V289.Postmark
import Evergreen.V289.SessionIdHash
import Evergreen.V289.Slack
import Evergreen.V289.Table
import Evergreen.V289.ToBackendLog
import Evergreen.V289.User
import Evergreen.V289.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V289.NonemptyDict.NonemptyDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V289.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V289.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V289.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V289.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V289.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V289.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V289.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V289.DmChannel.DmChannelId Evergreen.V289.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) Evergreen.V289.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V289.Pagination.Pagination Evergreen.V289.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash (Evergreen.V289.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V289.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V289.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V289.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash Evergreen.V289.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
        }
    | ExpandSection Evergreen.V289.User.AdminUiSection
    | CollapseSection Evergreen.V289.User.AdminUiSection
    | LogPageChanged (Evergreen.V289.Id.Id Evergreen.V289.Pagination.PageId) (Evergreen.V289.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V289.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V289.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V289.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V289.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V289.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V289.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V289.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V289.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | DeleteGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | RestoreGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | CollapseGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | HideLog (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    | UnhideLog (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    | DisconnectClient Evergreen.V289.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V289.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V289.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
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
    { table : Evergreen.V289.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V289.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V289.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V289.Editable.Model
    , publicVapidKey : Evergreen.V289.Editable.Model
    , privateVapidKey : Evergreen.V289.Editable.Model
    , openRouterKey : Evergreen.V289.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V289.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V289.Editable.Model
    , cloudflareAccountId : Evergreen.V289.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V289.Editable.Model
    , postmarkKey : Evergreen.V289.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V289.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V289.Id.Id Evergreen.V289.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V289.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V289.User.AdminUiSection
    | PressedExpandSection Evergreen.V289.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V289.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V289.Editable.Msg (Maybe Evergreen.V289.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V289.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V289.Editable.Msg Evergreen.V289.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V289.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V289.Editable.Msg (Maybe Evergreen.V289.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V289.Editable.Msg (Maybe Evergreen.V289.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V289.Editable.Msg (Maybe Evergreen.V289.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V289.Editable.Msg (Maybe Evergreen.V289.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V289.Editable.Msg Evergreen.V289.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V289.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V289.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V289.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V289.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V289.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V289.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
