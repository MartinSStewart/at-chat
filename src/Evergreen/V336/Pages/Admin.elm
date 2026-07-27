module Evergreen.V336.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V336.Cloudflare
import Evergreen.V336.Discord
import Evergreen.V336.DmChannelId
import Evergreen.V336.Editable
import Evergreen.V336.Id
import Evergreen.V336.LocalState
import Evergreen.V336.NonemptyDict
import Evergreen.V336.Pagination
import Evergreen.V336.Postmark
import Evergreen.V336.SessionIdHash
import Evergreen.V336.Slack
import Evergreen.V336.Table
import Evergreen.V336.ToBackendLog
import Evergreen.V336.User
import Evergreen.V336.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V336.Id.Id Evergreen.V336.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    | PressedExpandSection Evergreen.V336.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    | UserTableMsg Evergreen.V336.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V336.Editable.Msg (Maybe Evergreen.V336.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V336.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V336.Editable.Msg Evergreen.V336.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V336.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V336.Editable.Msg (Maybe Evergreen.V336.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V336.Editable.Msg (Maybe Evergreen.V336.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V336.Editable.Msg (Maybe Evergreen.V336.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V336.Editable.Msg (Maybe Evergreen.V336.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V336.Editable.Msg Evergreen.V336.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V336.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V336.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V336.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V336.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V336.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V336.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V336.NonemptyDict.NonemptyDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V336.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V336.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V336.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V336.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V336.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V336.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V336.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V336.DmChannelId.DmChannelId Evergreen.V336.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) Evergreen.V336.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V336.Pagination.Pagination Evergreen.V336.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash (Evergreen.V336.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V336.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V336.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V336.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash Evergreen.V336.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V336.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V336.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
        }
    | ExpandSection Evergreen.V336.User.AdminUiSection
    | CollapseSection Evergreen.V336.User.AdminUiSection
    | LogPageChanged (Evergreen.V336.Id.Id Evergreen.V336.Pagination.PageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V336.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V336.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V336.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V336.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V336.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V336.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V336.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V336.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | DeleteGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | RestoreGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (Result Evergreen.V336.Discord.HttpError (List Evergreen.V336.Discord.Role)))
    | ExpandGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | CollapseGuild (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    | HideLog (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    | UnhideLog (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    | DisconnectClient Evergreen.V336.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V336.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V336.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V336.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V336.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V336.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V336.Editable.Model
    , publicVapidKey : Evergreen.V336.Editable.Model
    , privateVapidKey : Evergreen.V336.Editable.Model
    , openRouterKey : Evergreen.V336.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V336.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V336.Editable.Model
    , cloudflareAccountId : Evergreen.V336.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V336.Editable.Model
    , postmarkKey : Evergreen.V336.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V336.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
