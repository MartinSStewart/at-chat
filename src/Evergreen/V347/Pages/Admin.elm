module Evergreen.V347.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V347.Cloudflare
import Evergreen.V347.Discord
import Evergreen.V347.DmChannelId
import Evergreen.V347.Editable
import Evergreen.V347.Id
import Evergreen.V347.LocalState
import Evergreen.V347.NonemptyDict
import Evergreen.V347.Pagination
import Evergreen.V347.Postmark
import Evergreen.V347.SessionIdHash
import Evergreen.V347.Slack
import Evergreen.V347.Table
import Evergreen.V347.ToBackendLog
import Evergreen.V347.User
import Evergreen.V347.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V347.Id.Id Evergreen.V347.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    | PressedExpandSection Evergreen.V347.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | UserTableMsg Evergreen.V347.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V347.Editable.Msg (Maybe Evergreen.V347.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V347.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V347.Editable.Msg Evergreen.V347.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V347.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V347.Editable.Msg (Maybe Evergreen.V347.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V347.Editable.Msg (Maybe Evergreen.V347.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V347.Editable.Msg (Maybe Evergreen.V347.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V347.Editable.Msg (Maybe Evergreen.V347.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V347.Editable.Msg Evergreen.V347.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V347.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V347.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V347.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V347.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V347.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V347.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V347.NonemptyDict.NonemptyDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Evergreen.V347.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V347.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V347.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V347.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V347.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V347.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V347.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V347.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V347.DmChannelId.DmChannelId Evergreen.V347.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) Evergreen.V347.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Evergreen.V347.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) Evergreen.V347.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) Evergreen.V347.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) Evergreen.V347.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V347.Pagination.Pagination Evergreen.V347.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V347.SessionIdHash.SessionIdHash (Evergreen.V347.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V347.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V347.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V347.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V347.SessionIdHash.SessionIdHash Evergreen.V347.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V347.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V347.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
        }
    | ExpandSection Evergreen.V347.User.AdminUiSection
    | CollapseSection Evergreen.V347.User.AdminUiSection
    | LogPageChanged (Evergreen.V347.Id.Id Evergreen.V347.Pagination.PageId) (Evergreen.V347.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V347.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V347.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V347.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V347.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V347.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V347.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V347.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V347.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | DeleteGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | RestoreGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.UserSession.ToBeFilledInByBackend (Result Evergreen.V347.Discord.HttpError (List Evergreen.V347.Discord.Role)))
    | ExpandGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | CollapseGuild (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId)
    | HideLog (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    | UnhideLog (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    | DisconnectClient Evergreen.V347.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V347.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V347.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V347.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V347.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V347.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V347.Editable.Model
    , publicVapidKey : Evergreen.V347.Editable.Model
    , privateVapidKey : Evergreen.V347.Editable.Model
    , openRouterKey : Evergreen.V347.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V347.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V347.Editable.Model
    , cloudflareAccountId : Evergreen.V347.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V347.Editable.Model
    , postmarkKey : Evergreen.V347.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V347.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
