module Evergreen.V290.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V290.Cloudflare
import Evergreen.V290.Discord
import Evergreen.V290.DmChannel
import Evergreen.V290.Editable
import Evergreen.V290.Id
import Evergreen.V290.LocalState
import Evergreen.V290.NonemptyDict
import Evergreen.V290.Pagination
import Evergreen.V290.Postmark
import Evergreen.V290.SessionIdHash
import Evergreen.V290.Slack
import Evergreen.V290.Table
import Evergreen.V290.ToBackendLog
import Evergreen.V290.User
import Evergreen.V290.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V290.NonemptyDict.NonemptyDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V290.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V290.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V290.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V290.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V290.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V290.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V290.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V290.DmChannel.DmChannelId Evergreen.V290.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) Evergreen.V290.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V290.Pagination.Pagination Evergreen.V290.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash (Evergreen.V290.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V290.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V290.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V290.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash Evergreen.V290.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
        }
    | ExpandSection Evergreen.V290.User.AdminUiSection
    | CollapseSection Evergreen.V290.User.AdminUiSection
    | LogPageChanged (Evergreen.V290.Id.Id Evergreen.V290.Pagination.PageId) (Evergreen.V290.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V290.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V290.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V290.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V290.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V290.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V290.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V290.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V290.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | DeleteGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | RestoreGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | CollapseGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | HideLog (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    | UnhideLog (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    | DisconnectClient Evergreen.V290.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V290.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V290.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
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
    { table : Evergreen.V290.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V290.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V290.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V290.Editable.Model
    , publicVapidKey : Evergreen.V290.Editable.Model
    , privateVapidKey : Evergreen.V290.Editable.Model
    , openRouterKey : Evergreen.V290.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V290.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V290.Editable.Model
    , cloudflareAccountId : Evergreen.V290.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V290.Editable.Model
    , postmarkKey : Evergreen.V290.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V290.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V290.Id.Id Evergreen.V290.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V290.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V290.User.AdminUiSection
    | PressedExpandSection Evergreen.V290.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V290.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V290.Editable.Msg (Maybe Evergreen.V290.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V290.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V290.Editable.Msg Evergreen.V290.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V290.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V290.Editable.Msg (Maybe Evergreen.V290.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V290.Editable.Msg (Maybe Evergreen.V290.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V290.Editable.Msg (Maybe Evergreen.V290.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V290.Editable.Msg (Maybe Evergreen.V290.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V290.Editable.Msg Evergreen.V290.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V290.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V290.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V290.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V290.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V290.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V290.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
