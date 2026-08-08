module Evergreen.V348.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V348.Cloudflare
import Evergreen.V348.Discord
import Evergreen.V348.DmChannelId
import Evergreen.V348.Editable
import Evergreen.V348.Id
import Evergreen.V348.LocalState
import Evergreen.V348.NonemptyDict
import Evergreen.V348.Pagination
import Evergreen.V348.Postmark
import Evergreen.V348.SessionIdHash
import Evergreen.V348.Slack
import Evergreen.V348.Table
import Evergreen.V348.ToBackendLog
import Evergreen.V348.User
import Evergreen.V348.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V348.Id.Id Evergreen.V348.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    | PressedExpandSection Evergreen.V348.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | UserTableMsg Evergreen.V348.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V348.Editable.Msg (Maybe Evergreen.V348.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V348.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V348.Editable.Msg Evergreen.V348.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V348.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V348.Editable.Msg (Maybe Evergreen.V348.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V348.Editable.Msg (Maybe Evergreen.V348.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V348.Editable.Msg (Maybe Evergreen.V348.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V348.Editable.Msg (Maybe Evergreen.V348.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V348.Editable.Msg Evergreen.V348.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V348.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V348.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V348.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V348.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V348.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V348.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V348.NonemptyDict.NonemptyDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V348.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V348.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V348.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V348.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V348.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V348.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V348.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V348.DmChannelId.DmChannelId Evergreen.V348.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) Evergreen.V348.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V348.Pagination.Pagination Evergreen.V348.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash (Evergreen.V348.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V348.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V348.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V348.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash Evergreen.V348.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V348.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V348.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
        }
    | ExpandSection Evergreen.V348.User.AdminUiSection
    | CollapseSection Evergreen.V348.User.AdminUiSection
    | LogPageChanged (Evergreen.V348.Id.Id Evergreen.V348.Pagination.PageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V348.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V348.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V348.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V348.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V348.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V348.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V348.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V348.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | DeleteGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | RestoreGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (Result Evergreen.V348.Discord.HttpError (List Evergreen.V348.Discord.Role)))
    | ExpandGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | CollapseGuild (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    | HideLog (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    | UnhideLog (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    | DisconnectClient Evergreen.V348.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V348.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V348.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V348.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V348.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V348.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V348.Editable.Model
    , publicVapidKey : Evergreen.V348.Editable.Model
    , privateVapidKey : Evergreen.V348.Editable.Model
    , openRouterKey : Evergreen.V348.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V348.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V348.Editable.Model
    , cloudflareAccountId : Evergreen.V348.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V348.Editable.Model
    , postmarkKey : Evergreen.V348.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V348.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
