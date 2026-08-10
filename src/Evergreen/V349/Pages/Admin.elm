module Evergreen.V349.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V349.Cloudflare
import Evergreen.V349.Discord
import Evergreen.V349.DmChannelId
import Evergreen.V349.Editable
import Evergreen.V349.Id
import Evergreen.V349.LocalState
import Evergreen.V349.NonemptyDict
import Evergreen.V349.Pagination
import Evergreen.V349.Postmark
import Evergreen.V349.SessionIdHash
import Evergreen.V349.Slack
import Evergreen.V349.Table
import Evergreen.V349.ToBackendLog
import Evergreen.V349.User
import Evergreen.V349.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V349.Id.Id Evergreen.V349.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    | PressedExpandSection Evergreen.V349.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | UserTableMsg Evergreen.V349.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V349.Editable.Msg (Maybe Evergreen.V349.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V349.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V349.Editable.Msg Evergreen.V349.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V349.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V349.Editable.Msg (Maybe Evergreen.V349.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V349.Editable.Msg (Maybe Evergreen.V349.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V349.Editable.Msg (Maybe Evergreen.V349.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V349.Editable.Msg (Maybe Evergreen.V349.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V349.Editable.Msg Evergreen.V349.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V349.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V349.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V349.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V349.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V349.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V349.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest


type alias InitAdminData =
    { users : Evergreen.V349.NonemptyDict.NonemptyDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V349.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V349.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V349.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V349.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V349.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V349.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V349.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V349.DmChannelId.DmChannelId Evergreen.V349.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) Evergreen.V349.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V349.Pagination.Pagination Evergreen.V349.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash (Evergreen.V349.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V349.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V349.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V349.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash Evergreen.V349.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V349.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V349.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
        }
    | ExpandSection Evergreen.V349.User.AdminUiSection
    | CollapseSection Evergreen.V349.User.AdminUiSection
    | LogPageChanged (Evergreen.V349.Id.Id Evergreen.V349.Pagination.PageId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V349.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V349.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V349.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V349.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V349.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V349.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V349.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V349.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | DeleteGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | RestoreGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.UserSession.ToBeFilledInByBackend (Result Evergreen.V349.Discord.HttpError (List Evergreen.V349.Discord.Role)))
    | ExpandGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | CollapseGuild (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    | HideLog (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    | UnhideLog (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    | DisconnectClient Evergreen.V349.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V349.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V349.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V349.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V349.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V349.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V349.Editable.Model
    , publicVapidKey : Evergreen.V349.Editable.Model
    , privateVapidKey : Evergreen.V349.Editable.Model
    , openRouterKey : Evergreen.V349.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V349.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V349.Editable.Model
    , cloudflareAccountId : Evergreen.V349.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V349.Editable.Model
    , postmarkKey : Evergreen.V349.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V349.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
