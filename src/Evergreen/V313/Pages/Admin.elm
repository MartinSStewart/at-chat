module Evergreen.V313.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V313.Cloudflare
import Evergreen.V313.Discord
import Evergreen.V313.DmChannelId
import Evergreen.V313.Editable
import Evergreen.V313.Id
import Evergreen.V313.LocalState
import Evergreen.V313.NonemptyDict
import Evergreen.V313.Pagination
import Evergreen.V313.Postmark
import Evergreen.V313.SessionIdHash
import Evergreen.V313.Slack
import Evergreen.V313.Table
import Evergreen.V313.ToBackendLog
import Evergreen.V313.User
import Evergreen.V313.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V313.Id.Id Evergreen.V313.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V313.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V313.User.AdminUiSection
    | PressedExpandSection Evergreen.V313.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V313.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V313.Editable.Msg (Maybe Evergreen.V313.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V313.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V313.Editable.Msg Evergreen.V313.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V313.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V313.Editable.Msg (Maybe Evergreen.V313.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V313.Editable.Msg (Maybe Evergreen.V313.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V313.Editable.Msg (Maybe Evergreen.V313.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V313.Editable.Msg (Maybe Evergreen.V313.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V313.Editable.Msg Evergreen.V313.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V313.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V313.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V313.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V313.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V313.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V313.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V313.NonemptyDict.NonemptyDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V313.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V313.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V313.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V313.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V313.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V313.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V313.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V313.DmChannelId.DmChannelId Evergreen.V313.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) Evergreen.V313.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V313.Pagination.Pagination Evergreen.V313.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash (Evergreen.V313.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V313.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V313.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V313.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash Evergreen.V313.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V313.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
        }
    | ExpandSection Evergreen.V313.User.AdminUiSection
    | CollapseSection Evergreen.V313.User.AdminUiSection
    | LogPageChanged (Evergreen.V313.Id.Id Evergreen.V313.Pagination.PageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V313.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V313.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V313.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V313.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V313.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V313.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V313.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V313.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | DeleteGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | RestoreGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | CollapseGuild (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    | HideLog (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    | UnhideLog (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    | DisconnectClient Evergreen.V313.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V313.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V313.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V313.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V313.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V313.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V313.Editable.Model
    , publicVapidKey : Evergreen.V313.Editable.Model
    , privateVapidKey : Evergreen.V313.Editable.Model
    , openRouterKey : Evergreen.V313.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V313.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V313.Editable.Model
    , cloudflareAccountId : Evergreen.V313.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V313.Editable.Model
    , postmarkKey : Evergreen.V313.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V313.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
