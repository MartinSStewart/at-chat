module Evergreen.V287.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V287.Cloudflare
import Evergreen.V287.Discord
import Evergreen.V287.DmChannel
import Evergreen.V287.Editable
import Evergreen.V287.Id
import Evergreen.V287.LocalState
import Evergreen.V287.NonemptyDict
import Evergreen.V287.Pagination
import Evergreen.V287.Postmark
import Evergreen.V287.SessionIdHash
import Evergreen.V287.Slack
import Evergreen.V287.Table
import Evergreen.V287.ToBackendLog
import Evergreen.V287.User
import Evergreen.V287.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V287.NonemptyDict.NonemptyDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V287.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V287.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V287.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V287.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V287.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V287.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V287.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V287.DmChannel.DmChannelId Evergreen.V287.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) Evergreen.V287.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V287.Pagination.Pagination Evergreen.V287.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash (Evergreen.V287.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V287.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V287.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V287.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash Evergreen.V287.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
        }
    | ExpandSection Evergreen.V287.User.AdminUiSection
    | CollapseSection Evergreen.V287.User.AdminUiSection
    | LogPageChanged (Evergreen.V287.Id.Id Evergreen.V287.Pagination.PageId) (Evergreen.V287.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V287.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V287.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V287.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V287.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V287.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V287.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V287.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V287.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | DeleteGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | RestoreGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | CollapseGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | HideLog (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    | UnhideLog (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    | DisconnectClient Evergreen.V287.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V287.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V287.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
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
    { table : Evergreen.V287.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V287.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V287.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V287.Editable.Model
    , publicVapidKey : Evergreen.V287.Editable.Model
    , privateVapidKey : Evergreen.V287.Editable.Model
    , openRouterKey : Evergreen.V287.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V287.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V287.Editable.Model
    , cloudflareAccountId : Evergreen.V287.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V287.Editable.Model
    , postmarkKey : Evergreen.V287.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V287.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V287.Id.Id Evergreen.V287.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V287.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V287.User.AdminUiSection
    | PressedExpandSection Evergreen.V287.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V287.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V287.Editable.Msg (Maybe Evergreen.V287.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V287.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V287.Editable.Msg Evergreen.V287.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V287.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V287.Editable.Msg (Maybe Evergreen.V287.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V287.Editable.Msg (Maybe Evergreen.V287.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V287.Editable.Msg (Maybe Evergreen.V287.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V287.Editable.Msg (Maybe Evergreen.V287.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V287.Editable.Msg Evergreen.V287.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V287.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V287.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V287.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V287.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V287.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V287.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
