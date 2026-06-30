module Evergreen.V297.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V297.Cloudflare
import Evergreen.V297.Discord
import Evergreen.V297.DmChannel
import Evergreen.V297.Editable
import Evergreen.V297.Id
import Evergreen.V297.LocalState
import Evergreen.V297.NonemptyDict
import Evergreen.V297.Pagination
import Evergreen.V297.Postmark
import Evergreen.V297.SessionIdHash
import Evergreen.V297.Slack
import Evergreen.V297.Table
import Evergreen.V297.ToBackendLog
import Evergreen.V297.User
import Evergreen.V297.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V297.NonemptyDict.NonemptyDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V297.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V297.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V297.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V297.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V297.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V297.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V297.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V297.DmChannel.DmChannelId Evergreen.V297.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) Evergreen.V297.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V297.Pagination.Pagination Evergreen.V297.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash (Evergreen.V297.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V297.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V297.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V297.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash Evergreen.V297.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
        }
    | ExpandSection Evergreen.V297.User.AdminUiSection
    | CollapseSection Evergreen.V297.User.AdminUiSection
    | LogPageChanged (Evergreen.V297.Id.Id Evergreen.V297.Pagination.PageId) (Evergreen.V297.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V297.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V297.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V297.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V297.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V297.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V297.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V297.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V297.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | DeleteGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | RestoreGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | CollapseGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | HideLog (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    | UnhideLog (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    | DisconnectClient Evergreen.V297.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V297.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V297.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
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
    { table : Evergreen.V297.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V297.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V297.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V297.Editable.Model
    , publicVapidKey : Evergreen.V297.Editable.Model
    , privateVapidKey : Evergreen.V297.Editable.Model
    , openRouterKey : Evergreen.V297.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V297.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V297.Editable.Model
    , cloudflareAccountId : Evergreen.V297.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V297.Editable.Model
    , postmarkKey : Evergreen.V297.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V297.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V297.Id.Id Evergreen.V297.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V297.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V297.User.AdminUiSection
    | PressedExpandSection Evergreen.V297.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V297.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V297.Editable.Msg (Maybe Evergreen.V297.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V297.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V297.Editable.Msg Evergreen.V297.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V297.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V297.Editable.Msg (Maybe Evergreen.V297.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V297.Editable.Msg (Maybe Evergreen.V297.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V297.Editable.Msg (Maybe Evergreen.V297.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V297.Editable.Msg (Maybe Evergreen.V297.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V297.Editable.Msg Evergreen.V297.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V297.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V297.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V297.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V297.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V297.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V297.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
