module Evergreen.V307.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V307.Cloudflare
import Evergreen.V307.Discord
import Evergreen.V307.DmChannelId
import Evergreen.V307.Editable
import Evergreen.V307.Id
import Evergreen.V307.LocalState
import Evergreen.V307.NonemptyDict
import Evergreen.V307.Pagination
import Evergreen.V307.Postmark
import Evergreen.V307.SessionIdHash
import Evergreen.V307.Slack
import Evergreen.V307.Table
import Evergreen.V307.ToBackendLog
import Evergreen.V307.User
import Evergreen.V307.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V307.Id.Id Evergreen.V307.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V307.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V307.User.AdminUiSection
    | PressedExpandSection Evergreen.V307.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V307.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V307.Editable.Msg (Maybe Evergreen.V307.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V307.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V307.Editable.Msg Evergreen.V307.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V307.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V307.Editable.Msg (Maybe Evergreen.V307.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V307.Editable.Msg (Maybe Evergreen.V307.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V307.Editable.Msg (Maybe Evergreen.V307.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V307.Editable.Msg (Maybe Evergreen.V307.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V307.Editable.Msg Evergreen.V307.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V307.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V307.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V307.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V307.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V307.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V307.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V307.NonemptyDict.NonemptyDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V307.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V307.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V307.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V307.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V307.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V307.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V307.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V307.DmChannelId.DmChannelId Evergreen.V307.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) Evergreen.V307.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V307.Pagination.Pagination Evergreen.V307.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash (Evergreen.V307.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V307.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V307.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V307.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash Evergreen.V307.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V307.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
        }
    | ExpandSection Evergreen.V307.User.AdminUiSection
    | CollapseSection Evergreen.V307.User.AdminUiSection
    | LogPageChanged (Evergreen.V307.Id.Id Evergreen.V307.Pagination.PageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V307.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V307.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V307.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V307.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V307.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V307.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V307.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V307.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | DeleteGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | RestoreGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | CollapseGuild (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    | HideLog (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    | UnhideLog (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    | DisconnectClient Evergreen.V307.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V307.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V307.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V307.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V307.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V307.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V307.Editable.Model
    , publicVapidKey : Evergreen.V307.Editable.Model
    , privateVapidKey : Evergreen.V307.Editable.Model
    , openRouterKey : Evergreen.V307.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V307.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V307.Editable.Model
    , cloudflareAccountId : Evergreen.V307.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V307.Editable.Model
    , postmarkKey : Evergreen.V307.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V307.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
