module Evergreen.V302.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V302.Cloudflare
import Evergreen.V302.Discord
import Evergreen.V302.DmChannel
import Evergreen.V302.Editable
import Evergreen.V302.Id
import Evergreen.V302.LocalState
import Evergreen.V302.NonemptyDict
import Evergreen.V302.Pagination
import Evergreen.V302.Postmark
import Evergreen.V302.SessionIdHash
import Evergreen.V302.Slack
import Evergreen.V302.Table
import Evergreen.V302.ToBackendLog
import Evergreen.V302.User
import Evergreen.V302.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V302.Id.Id Evergreen.V302.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V302.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V302.User.AdminUiSection
    | PressedExpandSection Evergreen.V302.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V302.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V302.Editable.Msg (Maybe Evergreen.V302.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V302.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V302.Editable.Msg Evergreen.V302.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V302.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V302.Editable.Msg (Maybe Evergreen.V302.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V302.Editable.Msg (Maybe Evergreen.V302.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V302.Editable.Msg (Maybe Evergreen.V302.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V302.Editable.Msg (Maybe Evergreen.V302.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V302.Editable.Msg Evergreen.V302.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V302.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V302.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V302.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V302.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V302.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V302.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V302.NonemptyDict.NonemptyDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V302.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V302.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V302.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V302.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V302.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V302.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V302.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V302.DmChannel.DmChannelId Evergreen.V302.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) Evergreen.V302.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V302.Pagination.Pagination Evergreen.V302.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash (Evergreen.V302.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V302.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V302.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V302.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash Evergreen.V302.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
        }
    | ExpandSection Evergreen.V302.User.AdminUiSection
    | CollapseSection Evergreen.V302.User.AdminUiSection
    | LogPageChanged (Evergreen.V302.Id.Id Evergreen.V302.Pagination.PageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V302.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V302.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V302.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V302.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V302.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V302.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V302.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V302.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | DeleteGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | RestoreGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | CollapseGuild (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    | HideLog (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    | UnhideLog (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    | DisconnectClient Evergreen.V302.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V302.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V302.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V302.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V302.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V302.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V302.Editable.Model
    , publicVapidKey : Evergreen.V302.Editable.Model
    , privateVapidKey : Evergreen.V302.Editable.Model
    , openRouterKey : Evergreen.V302.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V302.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V302.Editable.Model
    , cloudflareAccountId : Evergreen.V302.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V302.Editable.Model
    , postmarkKey : Evergreen.V302.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V302.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
