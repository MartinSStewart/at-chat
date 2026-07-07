module Evergreen.V305.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V305.Cloudflare
import Evergreen.V305.Discord
import Evergreen.V305.DmChannelId
import Evergreen.V305.Editable
import Evergreen.V305.Id
import Evergreen.V305.LocalState
import Evergreen.V305.NonemptyDict
import Evergreen.V305.Pagination
import Evergreen.V305.Postmark
import Evergreen.V305.SessionIdHash
import Evergreen.V305.Slack
import Evergreen.V305.Table
import Evergreen.V305.ToBackendLog
import Evergreen.V305.User
import Evergreen.V305.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V305.Id.Id Evergreen.V305.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V305.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V305.User.AdminUiSection
    | PressedExpandSection Evergreen.V305.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V305.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V305.Editable.Msg (Maybe Evergreen.V305.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V305.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V305.Editable.Msg Evergreen.V305.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V305.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V305.Editable.Msg (Maybe Evergreen.V305.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V305.Editable.Msg (Maybe Evergreen.V305.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V305.Editable.Msg (Maybe Evergreen.V305.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V305.Editable.Msg (Maybe Evergreen.V305.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V305.Editable.Msg Evergreen.V305.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V305.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V305.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V305.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V305.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V305.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V305.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V305.NonemptyDict.NonemptyDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Evergreen.V305.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V305.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V305.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V305.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V305.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V305.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V305.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V305.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V305.DmChannelId.DmChannelId Evergreen.V305.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) Evergreen.V305.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Evergreen.V305.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) Evergreen.V305.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) Evergreen.V305.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) Evergreen.V305.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V305.Pagination.Pagination Evergreen.V305.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V305.SessionIdHash.SessionIdHash (Evergreen.V305.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V305.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V305.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V305.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V305.SessionIdHash.SessionIdHash Evergreen.V305.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V305.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
        }
    | ExpandSection Evergreen.V305.User.AdminUiSection
    | CollapseSection Evergreen.V305.User.AdminUiSection
    | LogPageChanged (Evergreen.V305.Id.Id Evergreen.V305.Pagination.PageId) (Evergreen.V305.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V305.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V305.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V305.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V305.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V305.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V305.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V305.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V305.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    | DeleteGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | RestoreGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | CollapseGuild (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    | HideLog (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    | UnhideLog (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    | DisconnectClient Evergreen.V305.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V305.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V305.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V305.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V305.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V305.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V305.Editable.Model
    , publicVapidKey : Evergreen.V305.Editable.Model
    , privateVapidKey : Evergreen.V305.Editable.Model
    , openRouterKey : Evergreen.V305.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V305.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V305.Editable.Model
    , cloudflareAccountId : Evergreen.V305.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V305.Editable.Model
    , postmarkKey : Evergreen.V305.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V305.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
