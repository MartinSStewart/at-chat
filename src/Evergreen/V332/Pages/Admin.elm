module Evergreen.V332.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V332.Cloudflare
import Evergreen.V332.Discord
import Evergreen.V332.DmChannelId
import Evergreen.V332.Editable
import Evergreen.V332.Id
import Evergreen.V332.LocalState
import Evergreen.V332.NonemptyDict
import Evergreen.V332.Pagination
import Evergreen.V332.Postmark
import Evergreen.V332.SessionIdHash
import Evergreen.V332.Slack
import Evergreen.V332.Table
import Evergreen.V332.ToBackendLog
import Evergreen.V332.User
import Evergreen.V332.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V332.Id.Id Evergreen.V332.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    | PressedExpandSection Evergreen.V332.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    | UserTableMsg Evergreen.V332.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V332.Editable.Msg (Maybe Evergreen.V332.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V332.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V332.Editable.Msg Evergreen.V332.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V332.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V332.Editable.Msg (Maybe Evergreen.V332.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V332.Editable.Msg (Maybe Evergreen.V332.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V332.Editable.Msg (Maybe Evergreen.V332.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V332.Editable.Msg (Maybe Evergreen.V332.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V332.Editable.Msg Evergreen.V332.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V332.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V332.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V332.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V332.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V332.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V332.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V332.NonemptyDict.NonemptyDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V332.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V332.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V332.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V332.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V332.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V332.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V332.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V332.DmChannelId.DmChannelId Evergreen.V332.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) Evergreen.V332.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V332.Pagination.Pagination Evergreen.V332.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash (Evergreen.V332.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V332.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V332.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V332.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash Evergreen.V332.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V332.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V332.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
        }
    | ExpandSection Evergreen.V332.User.AdminUiSection
    | CollapseSection Evergreen.V332.User.AdminUiSection
    | LogPageChanged (Evergreen.V332.Id.Id Evergreen.V332.Pagination.PageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V332.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V332.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V332.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V332.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V332.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V332.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V332.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V332.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | DeleteGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | RestoreGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | CollapseGuild (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    | HideLog (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    | UnhideLog (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    | DisconnectClient Evergreen.V332.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V332.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V332.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V332.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V332.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V332.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V332.Editable.Model
    , publicVapidKey : Evergreen.V332.Editable.Model
    , privateVapidKey : Evergreen.V332.Editable.Model
    , openRouterKey : Evergreen.V332.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V332.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V332.Editable.Model
    , cloudflareAccountId : Evergreen.V332.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V332.Editable.Model
    , postmarkKey : Evergreen.V332.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V332.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
