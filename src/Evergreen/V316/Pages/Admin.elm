module Evergreen.V316.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V316.Cloudflare
import Evergreen.V316.Discord
import Evergreen.V316.DmChannelId
import Evergreen.V316.Editable
import Evergreen.V316.Id
import Evergreen.V316.LocalState
import Evergreen.V316.NonemptyDict
import Evergreen.V316.Pagination
import Evergreen.V316.Postmark
import Evergreen.V316.SessionIdHash
import Evergreen.V316.Slack
import Evergreen.V316.Table
import Evergreen.V316.ToBackendLog
import Evergreen.V316.User
import Evergreen.V316.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V316.Id.Id Evergreen.V316.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V316.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V316.User.AdminUiSection
    | PressedExpandSection Evergreen.V316.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V316.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V316.Editable.Msg (Maybe Evergreen.V316.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V316.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V316.Editable.Msg Evergreen.V316.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V316.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V316.Editable.Msg (Maybe Evergreen.V316.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V316.Editable.Msg (Maybe Evergreen.V316.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V316.Editable.Msg (Maybe Evergreen.V316.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V316.Editable.Msg (Maybe Evergreen.V316.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V316.Editable.Msg Evergreen.V316.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V316.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V316.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V316.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V316.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V316.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V316.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V316.NonemptyDict.NonemptyDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V316.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V316.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V316.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V316.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V316.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V316.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V316.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V316.DmChannelId.DmChannelId Evergreen.V316.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) Evergreen.V316.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V316.Pagination.Pagination Evergreen.V316.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash (Evergreen.V316.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V316.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V316.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V316.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash Evergreen.V316.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V316.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
        }
    | ExpandSection Evergreen.V316.User.AdminUiSection
    | CollapseSection Evergreen.V316.User.AdminUiSection
    | LogPageChanged (Evergreen.V316.Id.Id Evergreen.V316.Pagination.PageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V316.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V316.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V316.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V316.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V316.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V316.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V316.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V316.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | DeleteGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | RestoreGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | CollapseGuild (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    | HideLog (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    | UnhideLog (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    | DisconnectClient Evergreen.V316.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V316.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V316.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V316.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V316.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V316.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V316.Editable.Model
    , publicVapidKey : Evergreen.V316.Editable.Model
    , privateVapidKey : Evergreen.V316.Editable.Model
    , openRouterKey : Evergreen.V316.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V316.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V316.Editable.Model
    , cloudflareAccountId : Evergreen.V316.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V316.Editable.Model
    , postmarkKey : Evergreen.V316.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V316.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
