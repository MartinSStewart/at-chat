module Evergreen.V315.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V315.Cloudflare
import Evergreen.V315.Discord
import Evergreen.V315.DmChannelId
import Evergreen.V315.Editable
import Evergreen.V315.Id
import Evergreen.V315.LocalState
import Evergreen.V315.NonemptyDict
import Evergreen.V315.Pagination
import Evergreen.V315.Postmark
import Evergreen.V315.SessionIdHash
import Evergreen.V315.Slack
import Evergreen.V315.Table
import Evergreen.V315.ToBackendLog
import Evergreen.V315.User
import Evergreen.V315.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V315.Id.Id Evergreen.V315.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V315.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V315.User.AdminUiSection
    | PressedExpandSection Evergreen.V315.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V315.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V315.Editable.Msg (Maybe Evergreen.V315.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V315.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V315.Editable.Msg Evergreen.V315.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V315.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V315.Editable.Msg (Maybe Evergreen.V315.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V315.Editable.Msg (Maybe Evergreen.V315.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V315.Editable.Msg (Maybe Evergreen.V315.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V315.Editable.Msg (Maybe Evergreen.V315.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V315.Editable.Msg Evergreen.V315.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V315.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V315.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V315.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V315.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V315.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V315.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V315.NonemptyDict.NonemptyDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V315.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V315.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V315.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V315.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V315.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V315.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V315.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V315.DmChannelId.DmChannelId Evergreen.V315.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) Evergreen.V315.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V315.Pagination.Pagination Evergreen.V315.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash (Evergreen.V315.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V315.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V315.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V315.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash Evergreen.V315.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V315.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
        }
    | ExpandSection Evergreen.V315.User.AdminUiSection
    | CollapseSection Evergreen.V315.User.AdminUiSection
    | LogPageChanged (Evergreen.V315.Id.Id Evergreen.V315.Pagination.PageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V315.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V315.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V315.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V315.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V315.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V315.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V315.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V315.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | DeleteGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | RestoreGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | CollapseGuild (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    | HideLog (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    | UnhideLog (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    | DisconnectClient Evergreen.V315.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V315.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V315.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V315.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V315.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V315.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V315.Editable.Model
    , publicVapidKey : Evergreen.V315.Editable.Model
    , privateVapidKey : Evergreen.V315.Editable.Model
    , openRouterKey : Evergreen.V315.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V315.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V315.Editable.Model
    , cloudflareAccountId : Evergreen.V315.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V315.Editable.Model
    , postmarkKey : Evergreen.V315.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V315.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
