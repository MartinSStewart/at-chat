module Evergreen.V279.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V279.Cloudflare
import Evergreen.V279.Discord
import Evergreen.V279.DmChannel
import Evergreen.V279.Editable
import Evergreen.V279.Id
import Evergreen.V279.LocalState
import Evergreen.V279.NonemptyDict
import Evergreen.V279.Pagination
import Evergreen.V279.Postmark
import Evergreen.V279.SessionIdHash
import Evergreen.V279.Slack
import Evergreen.V279.Table
import Evergreen.V279.ToBackendLog
import Evergreen.V279.User
import Evergreen.V279.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V279.NonemptyDict.NonemptyDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V279.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V279.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V279.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V279.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V279.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V279.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V279.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V279.DmChannel.DmChannelId Evergreen.V279.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) Evergreen.V279.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V279.Pagination.Pagination Evergreen.V279.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash (Evergreen.V279.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V279.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V279.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V279.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash Evergreen.V279.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
        }
    | ExpandSection Evergreen.V279.User.AdminUiSection
    | CollapseSection Evergreen.V279.User.AdminUiSection
    | LogPageChanged (Evergreen.V279.Id.Id Evergreen.V279.Pagination.PageId) (Evergreen.V279.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V279.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V279.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V279.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V279.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V279.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V279.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V279.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V279.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | DeleteGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | RestoreGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | CollapseGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | HideLog (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    | UnhideLog (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    | DisconnectClient Evergreen.V279.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V279.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V279.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
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
    { table : Evergreen.V279.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V279.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V279.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V279.Editable.Model
    , publicVapidKey : Evergreen.V279.Editable.Model
    , privateVapidKey : Evergreen.V279.Editable.Model
    , openRouterKey : Evergreen.V279.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V279.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V279.Editable.Model
    , cloudflareAccountId : Evergreen.V279.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V279.Editable.Model
    , postmarkKey : Evergreen.V279.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V279.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V279.Id.Id Evergreen.V279.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V279.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V279.User.AdminUiSection
    | PressedExpandSection Evergreen.V279.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V279.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V279.Editable.Msg (Maybe Evergreen.V279.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V279.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V279.Editable.Msg Evergreen.V279.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V279.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V279.Editable.Msg (Maybe Evergreen.V279.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V279.Editable.Msg (Maybe Evergreen.V279.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V279.Editable.Msg (Maybe Evergreen.V279.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V279.Editable.Msg (Maybe Evergreen.V279.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V279.Editable.Msg Evergreen.V279.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V279.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V279.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V279.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V279.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V279.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V279.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
