module Evergreen.V317.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V317.Cloudflare
import Evergreen.V317.Discord
import Evergreen.V317.DmChannelId
import Evergreen.V317.Editable
import Evergreen.V317.Id
import Evergreen.V317.LocalState
import Evergreen.V317.NonemptyDict
import Evergreen.V317.Pagination
import Evergreen.V317.Postmark
import Evergreen.V317.SessionIdHash
import Evergreen.V317.Slack
import Evergreen.V317.Table
import Evergreen.V317.ToBackendLog
import Evergreen.V317.User
import Evergreen.V317.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V317.Id.Id Evergreen.V317.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V317.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V317.User.AdminUiSection
    | PressedExpandSection Evergreen.V317.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V317.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V317.Editable.Msg (Maybe Evergreen.V317.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V317.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V317.Editable.Msg Evergreen.V317.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V317.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V317.Editable.Msg (Maybe Evergreen.V317.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V317.Editable.Msg (Maybe Evergreen.V317.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V317.Editable.Msg (Maybe Evergreen.V317.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V317.Editable.Msg (Maybe Evergreen.V317.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V317.Editable.Msg Evergreen.V317.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V317.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V317.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V317.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V317.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V317.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V317.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V317.NonemptyDict.NonemptyDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V317.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V317.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V317.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V317.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V317.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V317.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V317.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V317.DmChannelId.DmChannelId Evergreen.V317.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) Evergreen.V317.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V317.Pagination.Pagination Evergreen.V317.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash (Evergreen.V317.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V317.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V317.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V317.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash Evergreen.V317.UserSession.UserSession
    , wordSpellingGameSwedish : Evergreen.V317.LocalState.WordSpellingGameSwedishStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
        }
    | ExpandSection Evergreen.V317.User.AdminUiSection
    | CollapseSection Evergreen.V317.User.AdminUiSection
    | LogPageChanged (Evergreen.V317.Id.Id Evergreen.V317.Pagination.PageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V317.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V317.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V317.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V317.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V317.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V317.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V317.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V317.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | DeleteGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | RestoreGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | CollapseGuild (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    | HideLog (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    | UnhideLog (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    | DisconnectClient Evergreen.V317.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V317.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V317.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V317.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V317.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V317.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V317.Editable.Model
    , publicVapidKey : Evergreen.V317.Editable.Model
    , privateVapidKey : Evergreen.V317.Editable.Model
    , openRouterKey : Evergreen.V317.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V317.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V317.Editable.Model
    , cloudflareAccountId : Evergreen.V317.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V317.Editable.Model
    , postmarkKey : Evergreen.V317.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V317.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
