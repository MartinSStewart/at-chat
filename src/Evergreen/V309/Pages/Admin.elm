module Evergreen.V309.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V309.Cloudflare
import Evergreen.V309.Discord
import Evergreen.V309.DmChannelId
import Evergreen.V309.Editable
import Evergreen.V309.Id
import Evergreen.V309.LocalState
import Evergreen.V309.NonemptyDict
import Evergreen.V309.Pagination
import Evergreen.V309.Postmark
import Evergreen.V309.SessionIdHash
import Evergreen.V309.Slack
import Evergreen.V309.Table
import Evergreen.V309.ToBackendLog
import Evergreen.V309.User
import Evergreen.V309.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V309.Id.Id Evergreen.V309.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V309.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V309.User.AdminUiSection
    | PressedExpandSection Evergreen.V309.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V309.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V309.Editable.Msg (Maybe Evergreen.V309.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V309.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V309.Editable.Msg Evergreen.V309.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V309.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V309.Editable.Msg (Maybe Evergreen.V309.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V309.Editable.Msg (Maybe Evergreen.V309.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V309.Editable.Msg (Maybe Evergreen.V309.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V309.Editable.Msg (Maybe Evergreen.V309.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V309.Editable.Msg Evergreen.V309.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V309.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V309.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V309.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V309.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V309.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V309.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V309.NonemptyDict.NonemptyDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V309.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V309.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V309.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V309.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V309.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V309.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V309.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V309.DmChannelId.DmChannelId Evergreen.V309.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) Evergreen.V309.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V309.Pagination.Pagination Evergreen.V309.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash (Evergreen.V309.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V309.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V309.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V309.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash Evergreen.V309.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V309.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
        }
    | ExpandSection Evergreen.V309.User.AdminUiSection
    | CollapseSection Evergreen.V309.User.AdminUiSection
    | LogPageChanged (Evergreen.V309.Id.Id Evergreen.V309.Pagination.PageId) (Evergreen.V309.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V309.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V309.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V309.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V309.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V309.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V309.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V309.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V309.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | DeleteGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | RestoreGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | CollapseGuild (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    | HideLog (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    | UnhideLog (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    | DisconnectClient Evergreen.V309.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V309.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V309.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V309.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V309.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V309.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V309.Editable.Model
    , publicVapidKey : Evergreen.V309.Editable.Model
    , privateVapidKey : Evergreen.V309.Editable.Model
    , openRouterKey : Evergreen.V309.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V309.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V309.Editable.Model
    , cloudflareAccountId : Evergreen.V309.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V309.Editable.Model
    , postmarkKey : Evergreen.V309.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V309.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
