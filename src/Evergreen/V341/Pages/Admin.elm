module Evergreen.V341.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V341.Cloudflare
import Evergreen.V341.Discord
import Evergreen.V341.DmChannelId
import Evergreen.V341.Editable
import Evergreen.V341.Id
import Evergreen.V341.LocalState
import Evergreen.V341.NonemptyDict
import Evergreen.V341.Pagination
import Evergreen.V341.Postmark
import Evergreen.V341.SessionIdHash
import Evergreen.V341.Slack
import Evergreen.V341.Table
import Evergreen.V341.ToBackendLog
import Evergreen.V341.User
import Evergreen.V341.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V341.Id.Id Evergreen.V341.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    | PressedExpandSection Evergreen.V341.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | UserTableMsg Evergreen.V341.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V341.Editable.Msg (Maybe Evergreen.V341.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V341.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V341.Editable.Msg Evergreen.V341.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V341.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V341.Editable.Msg (Maybe Evergreen.V341.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V341.Editable.Msg (Maybe Evergreen.V341.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V341.Editable.Msg (Maybe Evergreen.V341.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V341.Editable.Msg (Maybe Evergreen.V341.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V341.Editable.Msg Evergreen.V341.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V341.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V341.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V341.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V341.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V341.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V341.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V341.NonemptyDict.NonemptyDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V341.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V341.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V341.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V341.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V341.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V341.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V341.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V341.DmChannelId.DmChannelId Evergreen.V341.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) Evergreen.V341.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V341.Pagination.Pagination Evergreen.V341.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash (Evergreen.V341.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V341.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V341.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V341.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash Evergreen.V341.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V341.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V341.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
        }
    | ExpandSection Evergreen.V341.User.AdminUiSection
    | CollapseSection Evergreen.V341.User.AdminUiSection
    | LogPageChanged (Evergreen.V341.Id.Id Evergreen.V341.Pagination.PageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V341.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V341.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V341.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V341.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V341.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V341.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V341.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V341.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | DeleteGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | RestoreGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (Result Evergreen.V341.Discord.HttpError (List Evergreen.V341.Discord.Role)))
    | ExpandGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | CollapseGuild (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    | HideLog (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    | UnhideLog (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    | DisconnectClient Evergreen.V341.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V341.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V341.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V341.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V341.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V341.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V341.Editable.Model
    , publicVapidKey : Evergreen.V341.Editable.Model
    , privateVapidKey : Evergreen.V341.Editable.Model
    , openRouterKey : Evergreen.V341.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V341.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V341.Editable.Model
    , cloudflareAccountId : Evergreen.V341.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V341.Editable.Model
    , postmarkKey : Evergreen.V341.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V341.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
