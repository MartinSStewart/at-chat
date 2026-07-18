module Evergreen.V327.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V327.Cloudflare
import Evergreen.V327.Discord
import Evergreen.V327.DmChannelId
import Evergreen.V327.Editable
import Evergreen.V327.Id
import Evergreen.V327.LocalState
import Evergreen.V327.NonemptyDict
import Evergreen.V327.Pagination
import Evergreen.V327.Postmark
import Evergreen.V327.SessionIdHash
import Evergreen.V327.Slack
import Evergreen.V327.Table
import Evergreen.V327.ToBackendLog
import Evergreen.V327.User
import Evergreen.V327.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V327.Id.Id Evergreen.V327.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    | PressedExpandSection Evergreen.V327.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    | UserTableMsg Evergreen.V327.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V327.Editable.Msg (Maybe Evergreen.V327.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V327.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V327.Editable.Msg Evergreen.V327.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V327.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V327.Editable.Msg (Maybe Evergreen.V327.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V327.Editable.Msg (Maybe Evergreen.V327.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V327.Editable.Msg (Maybe Evergreen.V327.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V327.Editable.Msg (Maybe Evergreen.V327.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V327.Editable.Msg Evergreen.V327.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V327.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V327.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V327.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V327.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V327.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V327.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V327.NonemptyDict.NonemptyDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V327.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V327.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V327.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V327.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V327.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V327.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V327.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V327.DmChannelId.DmChannelId Evergreen.V327.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) Evergreen.V327.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V327.Pagination.Pagination Evergreen.V327.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash (Evergreen.V327.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V327.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V327.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V327.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash Evergreen.V327.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V327.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V327.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
        }
    | ExpandSection Evergreen.V327.User.AdminUiSection
    | CollapseSection Evergreen.V327.User.AdminUiSection
    | LogPageChanged (Evergreen.V327.Id.Id Evergreen.V327.Pagination.PageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V327.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V327.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V327.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V327.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V327.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V327.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V327.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V327.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | DeleteGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | RestoreGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | CollapseGuild (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    | HideLog (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    | UnhideLog (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    | DisconnectClient Evergreen.V327.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V327.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V327.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V327.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V327.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V327.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V327.Editable.Model
    , publicVapidKey : Evergreen.V327.Editable.Model
    , privateVapidKey : Evergreen.V327.Editable.Model
    , openRouterKey : Evergreen.V327.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V327.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V327.Editable.Model
    , cloudflareAccountId : Evergreen.V327.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V327.Editable.Model
    , postmarkKey : Evergreen.V327.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V327.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
