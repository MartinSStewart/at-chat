module Evergreen.V271.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V271.Cloudflare
import Evergreen.V271.Discord
import Evergreen.V271.DmChannel
import Evergreen.V271.Editable
import Evergreen.V271.Id
import Evergreen.V271.LocalState
import Evergreen.V271.NonemptyDict
import Evergreen.V271.Pagination
import Evergreen.V271.Postmark
import Evergreen.V271.SessionIdHash
import Evergreen.V271.Slack
import Evergreen.V271.Table
import Evergreen.V271.ToBackendLog
import Evergreen.V271.User
import Evergreen.V271.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V271.NonemptyDict.NonemptyDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V271.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V271.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V271.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V271.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V271.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V271.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V271.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V271.DmChannel.DmChannelId Evergreen.V271.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) Evergreen.V271.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V271.Pagination.Pagination Evergreen.V271.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash (Evergreen.V271.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V271.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V271.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V271.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash Evergreen.V271.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
        }
    | ExpandSection Evergreen.V271.User.AdminUiSection
    | CollapseSection Evergreen.V271.User.AdminUiSection
    | LogPageChanged (Evergreen.V271.Id.Id Evergreen.V271.Pagination.PageId) (Evergreen.V271.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V271.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V271.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V271.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V271.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V271.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V271.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V271.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V271.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | DeleteGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | RestoreGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | CollapseGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | HideLog (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    | UnhideLog (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    | DisconnectClient Evergreen.V271.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V271.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V271.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
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
    { table : Evergreen.V271.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V271.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V271.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V271.Editable.Model
    , publicVapidKey : Evergreen.V271.Editable.Model
    , privateVapidKey : Evergreen.V271.Editable.Model
    , openRouterKey : Evergreen.V271.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V271.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V271.Editable.Model
    , cloudflareAccountId : Evergreen.V271.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V271.Editable.Model
    , postmarkKey : Evergreen.V271.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V271.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V271.Id.Id Evergreen.V271.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V271.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V271.User.AdminUiSection
    | PressedExpandSection Evergreen.V271.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V271.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V271.Editable.Msg (Maybe Evergreen.V271.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V271.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V271.Editable.Msg Evergreen.V271.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V271.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V271.Editable.Msg (Maybe Evergreen.V271.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V271.Editable.Msg (Maybe Evergreen.V271.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V271.Editable.Msg (Maybe Evergreen.V271.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V271.Editable.Msg (Maybe Evergreen.V271.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V271.Editable.Msg Evergreen.V271.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V271.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V271.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V271.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V271.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V271.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V271.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
