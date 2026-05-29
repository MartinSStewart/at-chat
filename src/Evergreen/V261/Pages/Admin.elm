module Evergreen.V261.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V261.Cloudflare
import Evergreen.V261.Discord
import Evergreen.V261.DmChannel
import Evergreen.V261.Editable
import Evergreen.V261.Id
import Evergreen.V261.LocalState
import Evergreen.V261.NonemptyDict
import Evergreen.V261.Pagination
import Evergreen.V261.Postmark
import Evergreen.V261.SessionIdHash
import Evergreen.V261.Slack
import Evergreen.V261.Table
import Evergreen.V261.ToBackendLog
import Evergreen.V261.User
import Evergreen.V261.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V261.NonemptyDict.NonemptyDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V261.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V261.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V261.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V261.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V261.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V261.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V261.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V261.DmChannel.DmChannelId Evergreen.V261.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) Evergreen.V261.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V261.Pagination.Pagination Evergreen.V261.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V261.SessionIdHash.SessionIdHash (Evergreen.V261.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V261.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V261.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V261.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
        }
    | ExpandSection Evergreen.V261.User.AdminUiSection
    | CollapseSection Evergreen.V261.User.AdminUiSection
    | LogPageChanged (Evergreen.V261.Id.Id Evergreen.V261.Pagination.PageId) (Evergreen.V261.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V261.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V261.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V261.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V261.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V261.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V261.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V261.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V261.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | DeleteGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | RestoreGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | CollapseGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | HideLog (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    | UnhideLog (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    | DisconnectClient Evergreen.V261.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V261.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
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
    { table : Evergreen.V261.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V261.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V261.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V261.Editable.Model
    , publicVapidKey : Evergreen.V261.Editable.Model
    , privateVapidKey : Evergreen.V261.Editable.Model
    , openRouterKey : Evergreen.V261.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V261.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V261.Editable.Model
    , cloudflareAccountId : Evergreen.V261.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V261.Editable.Model
    , postmarkKey : Evergreen.V261.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V261.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V261.Id.Id Evergreen.V261.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V261.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V261.User.AdminUiSection
    | PressedExpandSection Evergreen.V261.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V261.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V261.Editable.Msg (Maybe Evergreen.V261.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V261.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V261.Editable.Msg Evergreen.V261.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V261.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V261.Editable.Msg (Maybe Evergreen.V261.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V261.Editable.Msg (Maybe Evergreen.V261.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V261.Editable.Msg (Maybe Evergreen.V261.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V261.Editable.Msg (Maybe Evergreen.V261.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V261.Editable.Msg Evergreen.V261.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V261.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V261.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V261.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V261.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V261.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
