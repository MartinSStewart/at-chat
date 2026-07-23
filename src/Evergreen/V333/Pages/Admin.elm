module Evergreen.V333.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V333.Cloudflare
import Evergreen.V333.Discord
import Evergreen.V333.DmChannelId
import Evergreen.V333.Editable
import Evergreen.V333.Id
import Evergreen.V333.LocalState
import Evergreen.V333.NonemptyDict
import Evergreen.V333.Pagination
import Evergreen.V333.Postmark
import Evergreen.V333.SessionIdHash
import Evergreen.V333.Slack
import Evergreen.V333.Table
import Evergreen.V333.ToBackendLog
import Evergreen.V333.User
import Evergreen.V333.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V333.Id.Id Evergreen.V333.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    | PressedExpandSection Evergreen.V333.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    | UserTableMsg Evergreen.V333.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V333.Editable.Msg (Maybe Evergreen.V333.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V333.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V333.Editable.Msg Evergreen.V333.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V333.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V333.Editable.Msg (Maybe Evergreen.V333.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V333.Editable.Msg (Maybe Evergreen.V333.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V333.Editable.Msg (Maybe Evergreen.V333.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V333.Editable.Msg (Maybe Evergreen.V333.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V333.Editable.Msg Evergreen.V333.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V333.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V333.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V333.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V333.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V333.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V333.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V333.NonemptyDict.NonemptyDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V333.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V333.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V333.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V333.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V333.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V333.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V333.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V333.DmChannelId.DmChannelId Evergreen.V333.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) Evergreen.V333.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V333.Pagination.Pagination Evergreen.V333.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash (Evergreen.V333.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V333.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V333.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V333.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash Evergreen.V333.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V333.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V333.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
        }
    | ExpandSection Evergreen.V333.User.AdminUiSection
    | CollapseSection Evergreen.V333.User.AdminUiSection
    | LogPageChanged (Evergreen.V333.Id.Id Evergreen.V333.Pagination.PageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V333.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V333.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V333.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V333.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V333.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V333.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V333.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V333.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | DeleteGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | RestoreGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (Result Evergreen.V333.Discord.HttpError (List Evergreen.V333.Discord.Role)))
    | ExpandGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | CollapseGuild (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    | HideLog (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    | UnhideLog (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    | DisconnectClient Evergreen.V333.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V333.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V333.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V333.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V333.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V333.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V333.Editable.Model
    , publicVapidKey : Evergreen.V333.Editable.Model
    , privateVapidKey : Evergreen.V333.Editable.Model
    , openRouterKey : Evergreen.V333.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V333.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V333.Editable.Model
    , cloudflareAccountId : Evergreen.V333.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V333.Editable.Model
    , postmarkKey : Evergreen.V333.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V333.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
