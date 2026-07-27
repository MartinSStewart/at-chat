module Evergreen.V335.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V335.Cloudflare
import Evergreen.V335.Discord
import Evergreen.V335.DmChannelId
import Evergreen.V335.Editable
import Evergreen.V335.Id
import Evergreen.V335.LocalState
import Evergreen.V335.NonemptyDict
import Evergreen.V335.Pagination
import Evergreen.V335.Postmark
import Evergreen.V335.SessionIdHash
import Evergreen.V335.Slack
import Evergreen.V335.Table
import Evergreen.V335.ToBackendLog
import Evergreen.V335.User
import Evergreen.V335.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V335.Id.Id Evergreen.V335.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    | PressedExpandSection Evergreen.V335.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    | UserTableMsg Evergreen.V335.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V335.Editable.Msg (Maybe Evergreen.V335.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V335.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V335.Editable.Msg Evergreen.V335.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V335.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V335.Editable.Msg (Maybe Evergreen.V335.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V335.Editable.Msg (Maybe Evergreen.V335.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V335.Editable.Msg (Maybe Evergreen.V335.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V335.Editable.Msg (Maybe Evergreen.V335.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V335.Editable.Msg Evergreen.V335.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V335.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V335.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V335.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V335.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V335.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V335.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V335.NonemptyDict.NonemptyDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V335.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V335.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V335.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V335.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V335.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V335.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V335.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V335.DmChannelId.DmChannelId Evergreen.V335.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V335.Pagination.Pagination Evergreen.V335.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash (Evergreen.V335.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V335.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V335.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V335.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash Evergreen.V335.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V335.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V335.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
        }
    | ExpandSection Evergreen.V335.User.AdminUiSection
    | CollapseSection Evergreen.V335.User.AdminUiSection
    | LogPageChanged (Evergreen.V335.Id.Id Evergreen.V335.Pagination.PageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V335.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V335.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V335.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V335.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V335.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V335.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V335.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V335.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | DeleteGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | RestoreGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (Result Evergreen.V335.Discord.HttpError (List Evergreen.V335.Discord.Role)))
    | ExpandGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | CollapseGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | HideLog (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    | UnhideLog (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    | DisconnectClient Evergreen.V335.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V335.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V335.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V335.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V335.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V335.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V335.Editable.Model
    , publicVapidKey : Evergreen.V335.Editable.Model
    , privateVapidKey : Evergreen.V335.Editable.Model
    , openRouterKey : Evergreen.V335.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V335.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V335.Editable.Model
    , cloudflareAccountId : Evergreen.V335.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V335.Editable.Model
    , postmarkKey : Evergreen.V335.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V335.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
