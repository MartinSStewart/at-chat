module Evergreen.V264.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V264.Cloudflare
import Evergreen.V264.Discord
import Evergreen.V264.DmChannel
import Evergreen.V264.Editable
import Evergreen.V264.Id
import Evergreen.V264.LocalState
import Evergreen.V264.NonemptyDict
import Evergreen.V264.Pagination
import Evergreen.V264.Postmark
import Evergreen.V264.SessionIdHash
import Evergreen.V264.Slack
import Evergreen.V264.Table
import Evergreen.V264.ToBackendLog
import Evergreen.V264.User
import Evergreen.V264.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V264.NonemptyDict.NonemptyDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V264.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V264.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V264.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V264.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V264.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V264.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V264.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V264.DmChannel.DmChannelId Evergreen.V264.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) Evergreen.V264.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V264.Pagination.Pagination Evergreen.V264.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash (Evergreen.V264.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V264.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V264.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V264.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash Evergreen.V264.UserSession.UserSession
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
        }
    | ExpandSection Evergreen.V264.User.AdminUiSection
    | CollapseSection Evergreen.V264.User.AdminUiSection
    | LogPageChanged (Evergreen.V264.Id.Id Evergreen.V264.Pagination.PageId) (Evergreen.V264.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V264.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V264.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V264.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V264.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V264.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V264.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V264.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V264.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | DeleteGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | RestoreGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | CollapseGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | HideLog (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    | UnhideLog (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    | DisconnectClient Evergreen.V264.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V264.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
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
    { table : Evergreen.V264.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V264.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V264.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V264.Editable.Model
    , publicVapidKey : Evergreen.V264.Editable.Model
    , privateVapidKey : Evergreen.V264.Editable.Model
    , openRouterKey : Evergreen.V264.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V264.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V264.Editable.Model
    , cloudflareAccountId : Evergreen.V264.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V264.Editable.Model
    , postmarkKey : Evergreen.V264.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V264.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V264.Id.Id Evergreen.V264.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V264.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V264.User.AdminUiSection
    | PressedExpandSection Evergreen.V264.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V264.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V264.Editable.Msg (Maybe Evergreen.V264.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V264.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V264.Editable.Msg Evergreen.V264.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V264.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V264.Editable.Msg (Maybe Evergreen.V264.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V264.Editable.Msg (Maybe Evergreen.V264.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V264.Editable.Msg (Maybe Evergreen.V264.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V264.Editable.Msg (Maybe Evergreen.V264.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V264.Editable.Msg Evergreen.V264.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V264.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V264.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V264.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V264.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V264.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
