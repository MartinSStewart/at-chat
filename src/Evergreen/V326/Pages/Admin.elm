module Evergreen.V326.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V326.Cloudflare
import Evergreen.V326.Discord
import Evergreen.V326.DmChannelId
import Evergreen.V326.Editable
import Evergreen.V326.Id
import Evergreen.V326.LocalState
import Evergreen.V326.NonemptyDict
import Evergreen.V326.Pagination
import Evergreen.V326.Postmark
import Evergreen.V326.SessionIdHash
import Evergreen.V326.Slack
import Evergreen.V326.Table
import Evergreen.V326.ToBackendLog
import Evergreen.V326.User
import Evergreen.V326.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V326.Id.Id Evergreen.V326.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    | PressedExpandSection Evergreen.V326.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | UserTableMsg Evergreen.V326.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V326.Editable.Msg (Maybe Evergreen.V326.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V326.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V326.Editable.Msg Evergreen.V326.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V326.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V326.Editable.Msg (Maybe Evergreen.V326.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V326.Editable.Msg (Maybe Evergreen.V326.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V326.Editable.Msg (Maybe Evergreen.V326.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V326.Editable.Msg (Maybe Evergreen.V326.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V326.Editable.Msg Evergreen.V326.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V326.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V326.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V326.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V326.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V326.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V326.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V326.NonemptyDict.NonemptyDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V326.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V326.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V326.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V326.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V326.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V326.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V326.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V326.DmChannelId.DmChannelId Evergreen.V326.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) Evergreen.V326.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V326.Pagination.Pagination Evergreen.V326.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash (Evergreen.V326.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V326.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V326.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V326.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash Evergreen.V326.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V326.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V326.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
        }
    | ExpandSection Evergreen.V326.User.AdminUiSection
    | CollapseSection Evergreen.V326.User.AdminUiSection
    | LogPageChanged (Evergreen.V326.Id.Id Evergreen.V326.Pagination.PageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V326.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V326.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V326.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V326.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V326.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V326.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V326.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V326.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | DeleteGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | RestoreGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | CollapseGuild (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    | HideLog (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    | UnhideLog (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    | DisconnectClient Evergreen.V326.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V326.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V326.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V326.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V326.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V326.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V326.Editable.Model
    , publicVapidKey : Evergreen.V326.Editable.Model
    , privateVapidKey : Evergreen.V326.Editable.Model
    , openRouterKey : Evergreen.V326.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V326.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V326.Editable.Model
    , cloudflareAccountId : Evergreen.V326.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V326.Editable.Model
    , postmarkKey : Evergreen.V326.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V326.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
