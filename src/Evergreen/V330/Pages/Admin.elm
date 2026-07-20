module Evergreen.V330.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V330.Cloudflare
import Evergreen.V330.Discord
import Evergreen.V330.DmChannelId
import Evergreen.V330.Editable
import Evergreen.V330.Id
import Evergreen.V330.LocalState
import Evergreen.V330.NonemptyDict
import Evergreen.V330.Pagination
import Evergreen.V330.Postmark
import Evergreen.V330.SessionIdHash
import Evergreen.V330.Slack
import Evergreen.V330.Table
import Evergreen.V330.ToBackendLog
import Evergreen.V330.User
import Evergreen.V330.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V330.Id.Id Evergreen.V330.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    | PressedExpandSection Evergreen.V330.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    | UserTableMsg Evergreen.V330.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V330.Editable.Msg (Maybe Evergreen.V330.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V330.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V330.Editable.Msg Evergreen.V330.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V330.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V330.Editable.Msg (Maybe Evergreen.V330.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V330.Editable.Msg (Maybe Evergreen.V330.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V330.Editable.Msg (Maybe Evergreen.V330.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V330.Editable.Msg (Maybe Evergreen.V330.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V330.Editable.Msg Evergreen.V330.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V330.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V330.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V330.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V330.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V330.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V330.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V330.NonemptyDict.NonemptyDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V330.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V330.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V330.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V330.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V330.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V330.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V330.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V330.DmChannelId.DmChannelId Evergreen.V330.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) Evergreen.V330.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V330.Pagination.Pagination Evergreen.V330.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash (Evergreen.V330.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V330.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V330.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V330.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash Evergreen.V330.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V330.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V330.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
        }
    | ExpandSection Evergreen.V330.User.AdminUiSection
    | CollapseSection Evergreen.V330.User.AdminUiSection
    | LogPageChanged (Evergreen.V330.Id.Id Evergreen.V330.Pagination.PageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V330.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V330.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V330.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V330.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V330.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V330.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V330.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V330.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | DeleteGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | RestoreGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | CollapseGuild (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    | HideLog (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    | UnhideLog (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    | DisconnectClient Evergreen.V330.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V330.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V330.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V330.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V330.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V330.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V330.Editable.Model
    , publicVapidKey : Evergreen.V330.Editable.Model
    , privateVapidKey : Evergreen.V330.Editable.Model
    , openRouterKey : Evergreen.V330.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V330.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V330.Editable.Model
    , cloudflareAccountId : Evergreen.V330.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V330.Editable.Model
    , postmarkKey : Evergreen.V330.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V330.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
