module Evergreen.V346.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V346.Cloudflare
import Evergreen.V346.Discord
import Evergreen.V346.DmChannelId
import Evergreen.V346.Editable
import Evergreen.V346.Id
import Evergreen.V346.LocalState
import Evergreen.V346.NonemptyDict
import Evergreen.V346.Pagination
import Evergreen.V346.Postmark
import Evergreen.V346.SessionIdHash
import Evergreen.V346.Slack
import Evergreen.V346.Table
import Evergreen.V346.ToBackendLog
import Evergreen.V346.User
import Evergreen.V346.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V346.Id.Id Evergreen.V346.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    | PressedExpandSection Evergreen.V346.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | UserTableMsg Evergreen.V346.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V346.Editable.Msg (Maybe Evergreen.V346.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V346.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V346.Editable.Msg Evergreen.V346.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V346.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V346.Editable.Msg (Maybe Evergreen.V346.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V346.Editable.Msg (Maybe Evergreen.V346.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V346.Editable.Msg (Maybe Evergreen.V346.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V346.Editable.Msg (Maybe Evergreen.V346.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V346.Editable.Msg Evergreen.V346.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V346.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V346.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V346.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V346.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V346.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V346.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V346.NonemptyDict.NonemptyDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V346.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V346.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V346.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V346.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V346.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V346.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V346.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V346.DmChannelId.DmChannelId Evergreen.V346.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) Evergreen.V346.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V346.Pagination.Pagination Evergreen.V346.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash (Evergreen.V346.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V346.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V346.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V346.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash Evergreen.V346.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V346.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V346.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
        }
    | ExpandSection Evergreen.V346.User.AdminUiSection
    | CollapseSection Evergreen.V346.User.AdminUiSection
    | LogPageChanged (Evergreen.V346.Id.Id Evergreen.V346.Pagination.PageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V346.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V346.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V346.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V346.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V346.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V346.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V346.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V346.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | DeleteGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | RestoreGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (Result Evergreen.V346.Discord.HttpError (List Evergreen.V346.Discord.Role)))
    | ExpandGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | CollapseGuild (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    | HideLog (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    | UnhideLog (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    | DisconnectClient Evergreen.V346.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V346.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V346.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V346.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V346.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V346.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V346.Editable.Model
    , publicVapidKey : Evergreen.V346.Editable.Model
    , privateVapidKey : Evergreen.V346.Editable.Model
    , openRouterKey : Evergreen.V346.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V346.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V346.Editable.Model
    , cloudflareAccountId : Evergreen.V346.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V346.Editable.Model
    , postmarkKey : Evergreen.V346.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V346.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
