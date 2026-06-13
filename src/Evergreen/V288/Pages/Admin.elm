module Evergreen.V288.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V288.Cloudflare
import Evergreen.V288.Discord
import Evergreen.V288.DmChannel
import Evergreen.V288.Editable
import Evergreen.V288.Id
import Evergreen.V288.LocalState
import Evergreen.V288.NonemptyDict
import Evergreen.V288.Pagination
import Evergreen.V288.Postmark
import Evergreen.V288.SessionIdHash
import Evergreen.V288.Slack
import Evergreen.V288.Table
import Evergreen.V288.ToBackendLog
import Evergreen.V288.User
import Evergreen.V288.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V288.NonemptyDict.NonemptyDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V288.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V288.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V288.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V288.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V288.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V288.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V288.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V288.DmChannel.DmChannelId Evergreen.V288.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) Evergreen.V288.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V288.Pagination.Pagination Evergreen.V288.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash (Evergreen.V288.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V288.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V288.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V288.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash Evergreen.V288.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
        }
    | ExpandSection Evergreen.V288.User.AdminUiSection
    | CollapseSection Evergreen.V288.User.AdminUiSection
    | LogPageChanged (Evergreen.V288.Id.Id Evergreen.V288.Pagination.PageId) (Evergreen.V288.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V288.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V288.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V288.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V288.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V288.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V288.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V288.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V288.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | DeleteGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | RestoreGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | CollapseGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | HideLog (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    | UnhideLog (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    | DisconnectClient Evergreen.V288.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V288.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V288.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
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
    { table : Evergreen.V288.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V288.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V288.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V288.Editable.Model
    , publicVapidKey : Evergreen.V288.Editable.Model
    , privateVapidKey : Evergreen.V288.Editable.Model
    , openRouterKey : Evergreen.V288.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V288.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V288.Editable.Model
    , cloudflareAccountId : Evergreen.V288.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V288.Editable.Model
    , postmarkKey : Evergreen.V288.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V288.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V288.Id.Id Evergreen.V288.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V288.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V288.User.AdminUiSection
    | PressedExpandSection Evergreen.V288.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V288.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V288.Editable.Msg (Maybe Evergreen.V288.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V288.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V288.Editable.Msg Evergreen.V288.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V288.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V288.Editable.Msg (Maybe Evergreen.V288.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V288.Editable.Msg (Maybe Evergreen.V288.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V288.Editable.Msg (Maybe Evergreen.V288.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V288.Editable.Msg (Maybe Evergreen.V288.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V288.Editable.Msg Evergreen.V288.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V288.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V288.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V288.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V288.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V288.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V288.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
