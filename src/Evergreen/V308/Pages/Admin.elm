module Evergreen.V308.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V308.Cloudflare
import Evergreen.V308.Discord
import Evergreen.V308.DmChannelId
import Evergreen.V308.Editable
import Evergreen.V308.Id
import Evergreen.V308.LocalState
import Evergreen.V308.NonemptyDict
import Evergreen.V308.Pagination
import Evergreen.V308.Postmark
import Evergreen.V308.SessionIdHash
import Evergreen.V308.Slack
import Evergreen.V308.Table
import Evergreen.V308.ToBackendLog
import Evergreen.V308.User
import Evergreen.V308.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V308.Id.Id Evergreen.V308.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V308.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V308.User.AdminUiSection
    | PressedExpandSection Evergreen.V308.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V308.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V308.Editable.Msg (Maybe Evergreen.V308.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V308.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V308.Editable.Msg Evergreen.V308.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V308.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V308.Editable.Msg (Maybe Evergreen.V308.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V308.Editable.Msg (Maybe Evergreen.V308.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V308.Editable.Msg (Maybe Evergreen.V308.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V308.Editable.Msg (Maybe Evergreen.V308.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V308.Editable.Msg Evergreen.V308.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V308.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V308.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V308.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V308.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V308.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V308.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V308.NonemptyDict.NonemptyDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V308.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V308.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V308.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V308.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V308.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V308.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V308.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V308.DmChannelId.DmChannelId Evergreen.V308.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) Evergreen.V308.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V308.Pagination.Pagination Evergreen.V308.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash (Evergreen.V308.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V308.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V308.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V308.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash Evergreen.V308.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V308.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
        }
    | ExpandSection Evergreen.V308.User.AdminUiSection
    | CollapseSection Evergreen.V308.User.AdminUiSection
    | LogPageChanged (Evergreen.V308.Id.Id Evergreen.V308.Pagination.PageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V308.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V308.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V308.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V308.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V308.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V308.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V308.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V308.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | DeleteGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | RestoreGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | CollapseGuild (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    | HideLog (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    | UnhideLog (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    | DisconnectClient Evergreen.V308.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V308.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V308.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V308.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V308.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V308.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V308.Editable.Model
    , publicVapidKey : Evergreen.V308.Editable.Model
    , privateVapidKey : Evergreen.V308.Editable.Model
    , openRouterKey : Evergreen.V308.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V308.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V308.Editable.Model
    , cloudflareAccountId : Evergreen.V308.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V308.Editable.Model
    , postmarkKey : Evergreen.V308.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V308.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
