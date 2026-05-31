module Evergreen.V262.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V262.Cloudflare
import Evergreen.V262.Discord
import Evergreen.V262.DmChannel
import Evergreen.V262.Editable
import Evergreen.V262.Id
import Evergreen.V262.LocalState
import Evergreen.V262.NonemptyDict
import Evergreen.V262.Pagination
import Evergreen.V262.Postmark
import Evergreen.V262.SessionIdHash
import Evergreen.V262.Slack
import Evergreen.V262.Table
import Evergreen.V262.ToBackendLog
import Evergreen.V262.User
import Evergreen.V262.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V262.NonemptyDict.NonemptyDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Evergreen.V262.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V262.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V262.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V262.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V262.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V262.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V262.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V262.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V262.DmChannel.DmChannelId Evergreen.V262.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) Evergreen.V262.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Evergreen.V262.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) Evergreen.V262.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) Evergreen.V262.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) Evergreen.V262.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V262.Pagination.Pagination Evergreen.V262.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V262.SessionIdHash.SessionIdHash (Evergreen.V262.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V262.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V262.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V262.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
        }
    | ExpandSection Evergreen.V262.User.AdminUiSection
    | CollapseSection Evergreen.V262.User.AdminUiSection
    | LogPageChanged (Evergreen.V262.Id.Id Evergreen.V262.Pagination.PageId) (Evergreen.V262.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V262.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V262.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V262.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V262.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V262.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V262.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V262.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V262.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    | DeleteGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | RestoreGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | CollapseGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    | HideLog (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    | UnhideLog (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    | DisconnectClient Evergreen.V262.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V262.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
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
    { table : Evergreen.V262.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V262.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V262.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V262.Editable.Model
    , publicVapidKey : Evergreen.V262.Editable.Model
    , privateVapidKey : Evergreen.V262.Editable.Model
    , openRouterKey : Evergreen.V262.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V262.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V262.Editable.Model
    , cloudflareAccountId : Evergreen.V262.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V262.Editable.Model
    , postmarkKey : Evergreen.V262.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V262.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
    = PressedLogPage (Evergreen.V262.Id.Id Evergreen.V262.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V262.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V262.User.AdminUiSection
    | PressedExpandSection Evergreen.V262.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V262.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V262.Editable.Msg (Maybe Evergreen.V262.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V262.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V262.Editable.Msg Evergreen.V262.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V262.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V262.Editable.Msg (Maybe Evergreen.V262.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V262.Editable.Msg (Maybe Evergreen.V262.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V262.Editable.Msg (Maybe Evergreen.V262.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V262.Editable.Msg (Maybe Evergreen.V262.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V262.Editable.Msg Evergreen.V262.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V262.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V262.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V262.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V262.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V262.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | LoadCloudflareEgressRequest
