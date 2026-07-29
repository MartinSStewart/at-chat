module Evergreen.V339.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V339.Cloudflare
import Evergreen.V339.Discord
import Evergreen.V339.DmChannelId
import Evergreen.V339.Editable
import Evergreen.V339.Id
import Evergreen.V339.LocalState
import Evergreen.V339.NonemptyDict
import Evergreen.V339.Pagination
import Evergreen.V339.Postmark
import Evergreen.V339.SessionIdHash
import Evergreen.V339.Slack
import Evergreen.V339.Table
import Evergreen.V339.ToBackendLog
import Evergreen.V339.User
import Evergreen.V339.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V339.Id.Id Evergreen.V339.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    | PressedExpandSection Evergreen.V339.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    | UserTableMsg Evergreen.V339.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V339.Editable.Msg (Maybe Evergreen.V339.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V339.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V339.Editable.Msg Evergreen.V339.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V339.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V339.Editable.Msg (Maybe Evergreen.V339.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V339.Editable.Msg (Maybe Evergreen.V339.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V339.Editable.Msg (Maybe Evergreen.V339.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V339.Editable.Msg (Maybe Evergreen.V339.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V339.Editable.Msg Evergreen.V339.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V339.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V339.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V339.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V339.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V339.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V339.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V339.NonemptyDict.NonemptyDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V339.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V339.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V339.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V339.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V339.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V339.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V339.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V339.DmChannelId.DmChannelId Evergreen.V339.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) Evergreen.V339.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V339.Pagination.Pagination Evergreen.V339.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash (Evergreen.V339.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V339.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V339.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V339.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash Evergreen.V339.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V339.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V339.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
        }
    | ExpandSection Evergreen.V339.User.AdminUiSection
    | CollapseSection Evergreen.V339.User.AdminUiSection
    | LogPageChanged (Evergreen.V339.Id.Id Evergreen.V339.Pagination.PageId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V339.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V339.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V339.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V339.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V339.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V339.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V339.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V339.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | DeleteGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | RestoreGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.UserSession.ToBeFilledInByBackend (Result Evergreen.V339.Discord.HttpError (List Evergreen.V339.Discord.Role)))
    | ExpandGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | CollapseGuild (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    | HideLog (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    | UnhideLog (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    | DisconnectClient Evergreen.V339.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V339.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V339.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V339.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V339.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V339.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V339.Editable.Model
    , publicVapidKey : Evergreen.V339.Editable.Model
    , privateVapidKey : Evergreen.V339.Editable.Model
    , openRouterKey : Evergreen.V339.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V339.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V339.Editable.Model
    , cloudflareAccountId : Evergreen.V339.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V339.Editable.Model
    , postmarkKey : Evergreen.V339.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V339.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
