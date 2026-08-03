module Evergreen.V344.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V344.Cloudflare
import Evergreen.V344.Discord
import Evergreen.V344.DmChannelId
import Evergreen.V344.Editable
import Evergreen.V344.Id
import Evergreen.V344.LocalState
import Evergreen.V344.NonemptyDict
import Evergreen.V344.Pagination
import Evergreen.V344.Postmark
import Evergreen.V344.SessionIdHash
import Evergreen.V344.Slack
import Evergreen.V344.Table
import Evergreen.V344.ToBackendLog
import Evergreen.V344.User
import Evergreen.V344.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V344.Id.Id Evergreen.V344.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    | PressedExpandSection Evergreen.V344.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | UserTableMsg Evergreen.V344.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V344.Editable.Msg (Maybe Evergreen.V344.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V344.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V344.Editable.Msg Evergreen.V344.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V344.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V344.Editable.Msg (Maybe Evergreen.V344.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V344.Editable.Msg (Maybe Evergreen.V344.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V344.Editable.Msg (Maybe Evergreen.V344.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V344.Editable.Msg (Maybe Evergreen.V344.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V344.Editable.Msg Evergreen.V344.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V344.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V344.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V344.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V344.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V344.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V344.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V344.NonemptyDict.NonemptyDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Evergreen.V344.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V344.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V344.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V344.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V344.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V344.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V344.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V344.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V344.DmChannelId.DmChannelId Evergreen.V344.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Evergreen.V344.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) Evergreen.V344.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V344.Pagination.Pagination Evergreen.V344.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V344.SessionIdHash.SessionIdHash (Evergreen.V344.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V344.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V344.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V344.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V344.SessionIdHash.SessionIdHash Evergreen.V344.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V344.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V344.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
        }
    | ExpandSection Evergreen.V344.User.AdminUiSection
    | CollapseSection Evergreen.V344.User.AdminUiSection
    | LogPageChanged (Evergreen.V344.Id.Id Evergreen.V344.Pagination.PageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V344.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V344.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V344.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V344.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V344.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V344.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V344.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V344.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | DeleteGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | RestoreGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (Result Evergreen.V344.Discord.HttpError (List Evergreen.V344.Discord.Role)))
    | ExpandGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | CollapseGuild (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId)
    | HideLog (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    | UnhideLog (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    | DisconnectClient Evergreen.V344.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V344.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V344.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V344.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V344.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V344.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V344.Editable.Model
    , publicVapidKey : Evergreen.V344.Editable.Model
    , privateVapidKey : Evergreen.V344.Editable.Model
    , openRouterKey : Evergreen.V344.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V344.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V344.Editable.Model
    , cloudflareAccountId : Evergreen.V344.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V344.Editable.Model
    , postmarkKey : Evergreen.V344.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V344.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
