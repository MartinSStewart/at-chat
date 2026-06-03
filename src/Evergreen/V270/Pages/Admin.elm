module Evergreen.V270.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V270.Cloudflare
import Evergreen.V270.Discord
import Evergreen.V270.DmChannel
import Evergreen.V270.Editable
import Evergreen.V270.Id
import Evergreen.V270.LocalState
import Evergreen.V270.NonemptyDict
import Evergreen.V270.Pagination
import Evergreen.V270.Postmark
import Evergreen.V270.SessionIdHash
import Evergreen.V270.Slack
import Evergreen.V270.Table
import Evergreen.V270.ToBackendLog
import Evergreen.V270.User
import Evergreen.V270.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V270.NonemptyDict.NonemptyDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V270.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V270.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V270.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V270.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V270.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V270.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V270.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V270.DmChannel.DmChannelId Evergreen.V270.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) Evergreen.V270.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V270.Pagination.Pagination Evergreen.V270.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash (Evergreen.V270.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V270.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V270.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V270.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash Evergreen.V270.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
        }
    | ExpandSection Evergreen.V270.User.AdminUiSection
    | CollapseSection Evergreen.V270.User.AdminUiSection
    | LogPageChanged (Evergreen.V270.Id.Id Evergreen.V270.Pagination.PageId) (Evergreen.V270.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V270.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V270.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V270.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V270.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V270.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V270.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V270.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V270.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | DeleteGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | RestoreGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | CollapseGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | HideLog (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    | UnhideLog (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    | DisconnectClient Evergreen.V270.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V270.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V270.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
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
    { table : Evergreen.V270.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V270.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V270.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V270.Editable.Model
    , publicVapidKey : Evergreen.V270.Editable.Model
    , privateVapidKey : Evergreen.V270.Editable.Model
    , openRouterKey : Evergreen.V270.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V270.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V270.Editable.Model
    , cloudflareAccountId : Evergreen.V270.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V270.Editable.Model
    , postmarkKey : Evergreen.V270.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V270.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V270.Id.Id Evergreen.V270.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V270.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V270.User.AdminUiSection
    | PressedExpandSection Evergreen.V270.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V270.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V270.Editable.Msg (Maybe Evergreen.V270.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V270.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V270.Editable.Msg Evergreen.V270.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V270.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V270.Editable.Msg (Maybe Evergreen.V270.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V270.Editable.Msg (Maybe Evergreen.V270.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V270.Editable.Msg (Maybe Evergreen.V270.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V270.Editable.Msg (Maybe Evergreen.V270.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V270.Editable.Msg Evergreen.V270.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V270.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V270.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V270.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V270.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V270.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V270.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
