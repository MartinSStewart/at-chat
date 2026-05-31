module Evergreen.V263.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V263.Cloudflare
import Evergreen.V263.Discord
import Evergreen.V263.DmChannel
import Evergreen.V263.Editable
import Evergreen.V263.Id
import Evergreen.V263.LocalState
import Evergreen.V263.NonemptyDict
import Evergreen.V263.Pagination
import Evergreen.V263.Postmark
import Evergreen.V263.SessionIdHash
import Evergreen.V263.Slack
import Evergreen.V263.Table
import Evergreen.V263.ToBackendLog
import Evergreen.V263.User
import Evergreen.V263.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V263.NonemptyDict.NonemptyDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V263.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V263.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V263.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V263.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V263.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V263.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V263.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V263.DmChannel.DmChannelId Evergreen.V263.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) Evergreen.V263.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V263.Pagination.Pagination Evergreen.V263.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V263.SessionIdHash.SessionIdHash (Evergreen.V263.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V263.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V263.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V263.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
        }
    | ExpandSection Evergreen.V263.User.AdminUiSection
    | CollapseSection Evergreen.V263.User.AdminUiSection
    | LogPageChanged (Evergreen.V263.Id.Id Evergreen.V263.Pagination.PageId) (Evergreen.V263.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V263.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V263.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V263.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V263.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V263.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V263.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V263.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V263.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | DeleteGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | RestoreGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | CollapseGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | HideLog (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    | UnhideLog (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    | DisconnectClient Evergreen.V263.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V263.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
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
    { table : Evergreen.V263.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V263.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V263.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V263.Editable.Model
    , publicVapidKey : Evergreen.V263.Editable.Model
    , privateVapidKey : Evergreen.V263.Editable.Model
    , openRouterKey : Evergreen.V263.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V263.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V263.Editable.Model
    , cloudflareAccountId : Evergreen.V263.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V263.Editable.Model
    , postmarkKey : Evergreen.V263.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V263.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V263.Id.Id Evergreen.V263.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V263.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V263.User.AdminUiSection
    | PressedExpandSection Evergreen.V263.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V263.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V263.Editable.Msg (Maybe Evergreen.V263.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V263.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V263.Editable.Msg Evergreen.V263.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V263.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V263.Editable.Msg (Maybe Evergreen.V263.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V263.Editable.Msg (Maybe Evergreen.V263.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V263.Editable.Msg (Maybe Evergreen.V263.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V263.Editable.Msg (Maybe Evergreen.V263.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V263.Editable.Msg Evergreen.V263.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V263.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V263.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V263.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V263.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V263.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
