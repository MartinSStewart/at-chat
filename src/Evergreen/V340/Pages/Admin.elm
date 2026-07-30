module Evergreen.V340.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V340.Cloudflare
import Evergreen.V340.Discord
import Evergreen.V340.DmChannelId
import Evergreen.V340.Editable
import Evergreen.V340.Id
import Evergreen.V340.LocalState
import Evergreen.V340.NonemptyDict
import Evergreen.V340.Pagination
import Evergreen.V340.Postmark
import Evergreen.V340.SessionIdHash
import Evergreen.V340.Slack
import Evergreen.V340.Table
import Evergreen.V340.ToBackendLog
import Evergreen.V340.User
import Evergreen.V340.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V340.Id.Id Evergreen.V340.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    | PressedExpandSection Evergreen.V340.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | UserTableMsg Evergreen.V340.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V340.Editable.Msg (Maybe Evergreen.V340.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V340.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V340.Editable.Msg Evergreen.V340.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V340.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V340.Editable.Msg (Maybe Evergreen.V340.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V340.Editable.Msg (Maybe Evergreen.V340.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V340.Editable.Msg (Maybe Evergreen.V340.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V340.Editable.Msg (Maybe Evergreen.V340.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V340.Editable.Msg Evergreen.V340.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V340.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V340.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V340.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V340.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V340.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V340.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V340.NonemptyDict.NonemptyDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V340.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V340.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V340.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V340.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V340.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V340.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V340.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V340.DmChannelId.DmChannelId Evergreen.V340.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) Evergreen.V340.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V340.Pagination.Pagination Evergreen.V340.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash (Evergreen.V340.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V340.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V340.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V340.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash Evergreen.V340.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V340.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V340.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
        }
    | ExpandSection Evergreen.V340.User.AdminUiSection
    | CollapseSection Evergreen.V340.User.AdminUiSection
    | LogPageChanged (Evergreen.V340.Id.Id Evergreen.V340.Pagination.PageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V340.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V340.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V340.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V340.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V340.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V340.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V340.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V340.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | DeleteGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | RestoreGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (Result Evergreen.V340.Discord.HttpError (List Evergreen.V340.Discord.Role)))
    | ExpandGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | CollapseGuild (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    | HideLog (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    | UnhideLog (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    | DisconnectClient Evergreen.V340.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V340.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V340.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V340.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V340.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V340.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V340.Editable.Model
    , publicVapidKey : Evergreen.V340.Editable.Model
    , privateVapidKey : Evergreen.V340.Editable.Model
    , openRouterKey : Evergreen.V340.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V340.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V340.Editable.Model
    , cloudflareAccountId : Evergreen.V340.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V340.Editable.Model
    , postmarkKey : Evergreen.V340.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V340.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
