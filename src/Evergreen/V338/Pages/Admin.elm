module Evergreen.V338.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V338.Cloudflare
import Evergreen.V338.Discord
import Evergreen.V338.DmChannelId
import Evergreen.V338.Editable
import Evergreen.V338.Id
import Evergreen.V338.LocalState
import Evergreen.V338.NonemptyDict
import Evergreen.V338.Pagination
import Evergreen.V338.Postmark
import Evergreen.V338.SessionIdHash
import Evergreen.V338.Slack
import Evergreen.V338.Table
import Evergreen.V338.ToBackendLog
import Evergreen.V338.User
import Evergreen.V338.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V338.Id.Id Evergreen.V338.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    | PressedExpandSection Evergreen.V338.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    | UserTableMsg Evergreen.V338.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V338.Editable.Msg (Maybe Evergreen.V338.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V338.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V338.Editable.Msg Evergreen.V338.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V338.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V338.Editable.Msg (Maybe Evergreen.V338.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V338.Editable.Msg (Maybe Evergreen.V338.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V338.Editable.Msg (Maybe Evergreen.V338.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V338.Editable.Msg (Maybe Evergreen.V338.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V338.Editable.Msg Evergreen.V338.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V338.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V338.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V338.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V338.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V338.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V338.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V338.NonemptyDict.NonemptyDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V338.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V338.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V338.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V338.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V338.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V338.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V338.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V338.DmChannelId.DmChannelId Evergreen.V338.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) Evergreen.V338.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V338.Pagination.Pagination Evergreen.V338.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash (Evergreen.V338.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V338.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V338.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V338.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash Evergreen.V338.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V338.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V338.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
        }
    | ExpandSection Evergreen.V338.User.AdminUiSection
    | CollapseSection Evergreen.V338.User.AdminUiSection
    | LogPageChanged (Evergreen.V338.Id.Id Evergreen.V338.Pagination.PageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V338.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V338.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V338.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V338.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V338.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V338.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V338.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V338.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | DeleteGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | RestoreGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (Result Evergreen.V338.Discord.HttpError (List Evergreen.V338.Discord.Role)))
    | ExpandGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | CollapseGuild (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    | HideLog (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    | UnhideLog (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    | DisconnectClient Evergreen.V338.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V338.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V338.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V338.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V338.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V338.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V338.Editable.Model
    , publicVapidKey : Evergreen.V338.Editable.Model
    , privateVapidKey : Evergreen.V338.Editable.Model
    , openRouterKey : Evergreen.V338.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V338.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V338.Editable.Model
    , cloudflareAccountId : Evergreen.V338.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V338.Editable.Model
    , postmarkKey : Evergreen.V338.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V338.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
