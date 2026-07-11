module Evergreen.V312.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V312.Cloudflare
import Evergreen.V312.Discord
import Evergreen.V312.DmChannelId
import Evergreen.V312.Editable
import Evergreen.V312.Id
import Evergreen.V312.LocalState
import Evergreen.V312.NonemptyDict
import Evergreen.V312.Pagination
import Evergreen.V312.Postmark
import Evergreen.V312.SessionIdHash
import Evergreen.V312.Slack
import Evergreen.V312.Table
import Evergreen.V312.ToBackendLog
import Evergreen.V312.User
import Evergreen.V312.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V312.Id.Id Evergreen.V312.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V312.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V312.User.AdminUiSection
    | PressedExpandSection Evergreen.V312.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V312.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V312.Editable.Msg (Maybe Evergreen.V312.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V312.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V312.Editable.Msg Evergreen.V312.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V312.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V312.Editable.Msg (Maybe Evergreen.V312.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V312.Editable.Msg (Maybe Evergreen.V312.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V312.Editable.Msg (Maybe Evergreen.V312.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V312.Editable.Msg (Maybe Evergreen.V312.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V312.Editable.Msg Evergreen.V312.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V312.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V312.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V312.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V312.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V312.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V312.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V312.NonemptyDict.NonemptyDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V312.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V312.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V312.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V312.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V312.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V312.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V312.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V312.DmChannelId.DmChannelId Evergreen.V312.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) Evergreen.V312.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V312.Pagination.Pagination Evergreen.V312.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash (Evergreen.V312.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V312.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V312.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V312.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash Evergreen.V312.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V312.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
        }
    | ExpandSection Evergreen.V312.User.AdminUiSection
    | CollapseSection Evergreen.V312.User.AdminUiSection
    | LogPageChanged (Evergreen.V312.Id.Id Evergreen.V312.Pagination.PageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V312.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V312.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V312.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V312.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V312.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V312.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V312.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V312.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | DeleteGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | RestoreGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | CollapseGuild (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    | HideLog (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    | UnhideLog (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    | DisconnectClient Evergreen.V312.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V312.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V312.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V312.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V312.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V312.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V312.Editable.Model
    , publicVapidKey : Evergreen.V312.Editable.Model
    , privateVapidKey : Evergreen.V312.Editable.Model
    , openRouterKey : Evergreen.V312.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V312.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V312.Editable.Model
    , cloudflareAccountId : Evergreen.V312.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V312.Editable.Model
    , postmarkKey : Evergreen.V312.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V312.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
