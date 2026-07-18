module Evergreen.V328.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V328.Cloudflare
import Evergreen.V328.Discord
import Evergreen.V328.DmChannelId
import Evergreen.V328.Editable
import Evergreen.V328.Id
import Evergreen.V328.LocalState
import Evergreen.V328.NonemptyDict
import Evergreen.V328.Pagination
import Evergreen.V328.Postmark
import Evergreen.V328.SessionIdHash
import Evergreen.V328.Slack
import Evergreen.V328.Table
import Evergreen.V328.ToBackendLog
import Evergreen.V328.User
import Evergreen.V328.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V328.Id.Id Evergreen.V328.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    | PressedExpandSection Evergreen.V328.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    | UserTableMsg Evergreen.V328.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V328.Editable.Msg (Maybe Evergreen.V328.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V328.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V328.Editable.Msg Evergreen.V328.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V328.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V328.Editable.Msg (Maybe Evergreen.V328.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V328.Editable.Msg (Maybe Evergreen.V328.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V328.Editable.Msg (Maybe Evergreen.V328.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V328.Editable.Msg (Maybe Evergreen.V328.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V328.Editable.Msg Evergreen.V328.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V328.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V328.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V328.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V328.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V328.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V328.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V328.NonemptyDict.NonemptyDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Evergreen.V328.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V328.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V328.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V328.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V328.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V328.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V328.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V328.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V328.DmChannelId.DmChannelId Evergreen.V328.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) Evergreen.V328.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Evergreen.V328.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) Evergreen.V328.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) Evergreen.V328.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) Evergreen.V328.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V328.Pagination.Pagination Evergreen.V328.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V328.SessionIdHash.SessionIdHash (Evergreen.V328.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V328.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V328.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V328.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V328.SessionIdHash.SessionIdHash Evergreen.V328.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V328.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V328.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
        }
    | ExpandSection Evergreen.V328.User.AdminUiSection
    | CollapseSection Evergreen.V328.User.AdminUiSection
    | LogPageChanged (Evergreen.V328.Id.Id Evergreen.V328.Pagination.PageId) (Evergreen.V328.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V328.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V328.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V328.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V328.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V328.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V328.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V328.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V328.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    | DeleteGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | RestoreGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | CollapseGuild (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    | HideLog (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    | UnhideLog (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    | DisconnectClient Evergreen.V328.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V328.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V328.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V328.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V328.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V328.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V328.Editable.Model
    , publicVapidKey : Evergreen.V328.Editable.Model
    , privateVapidKey : Evergreen.V328.Editable.Model
    , openRouterKey : Evergreen.V328.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V328.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V328.Editable.Model
    , cloudflareAccountId : Evergreen.V328.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V328.Editable.Model
    , postmarkKey : Evergreen.V328.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V328.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
