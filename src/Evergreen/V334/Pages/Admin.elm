module Evergreen.V334.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V334.Cloudflare
import Evergreen.V334.Discord
import Evergreen.V334.DmChannelId
import Evergreen.V334.Editable
import Evergreen.V334.Id
import Evergreen.V334.LocalState
import Evergreen.V334.NonemptyDict
import Evergreen.V334.Pagination
import Evergreen.V334.Postmark
import Evergreen.V334.SessionIdHash
import Evergreen.V334.Slack
import Evergreen.V334.Table
import Evergreen.V334.ToBackendLog
import Evergreen.V334.User
import Evergreen.V334.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V334.Id.Id Evergreen.V334.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    | PressedExpandSection Evergreen.V334.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    | UserTableMsg Evergreen.V334.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V334.Editable.Msg (Maybe Evergreen.V334.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V334.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V334.Editable.Msg Evergreen.V334.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V334.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V334.Editable.Msg (Maybe Evergreen.V334.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V334.Editable.Msg (Maybe Evergreen.V334.Cloudflare.AppId))
    | CloudflareAccountIdEditableMsg (Evergreen.V334.Editable.Msg (Maybe Evergreen.V334.Cloudflare.AccountId))
    | CloudflareAnalyticsApiTokenEditableMsg (Evergreen.V334.Editable.Msg (Maybe Evergreen.V334.Cloudflare.AnalyticsApiToken))
    | PostmarkKeyEditableMsg (Evergreen.V334.Editable.Msg Evergreen.V334.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V334.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V334.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V334.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V334.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V334.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V334.Cloudflare.SessionStateResponse)
    | PressedLoadCloudflareEgress


type alias InitAdminData =
    { users : Evergreen.V334.NonemptyDict.NonemptyDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Evergreen.V334.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V334.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V334.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V334.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V334.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V334.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V334.Cloudflare.AnalyticsApiToken
    , postmarkApiKey : Evergreen.V334.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V334.DmChannelId.DmChannelId Evergreen.V334.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) Evergreen.V334.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Evergreen.V334.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) Evergreen.V334.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) Evergreen.V334.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) Evergreen.V334.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V334.Pagination.Pagination Evergreen.V334.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V334.SessionIdHash.SessionIdHash (Evergreen.V334.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V334.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V334.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V334.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V334.SessionIdHash.SessionIdHash Evergreen.V334.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V334.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V334.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
        }
    | ExpandSection Evergreen.V334.User.AdminUiSection
    | CollapseSection Evergreen.V334.User.AdminUiSection
    | LogPageChanged (Evergreen.V334.Id.Id Evergreen.V334.Pagination.PageId) (Evergreen.V334.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V334.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V334.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V334.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V334.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V334.Cloudflare.AppId)
    | SetCloudflareAccountId (Maybe Evergreen.V334.Cloudflare.AccountId)
    | SetCloudflareAnalyticsApiToken (Maybe Evergreen.V334.Cloudflare.AnalyticsApiToken)
    | SetPostmarkKey Evergreen.V334.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | DeleteGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | RestoreGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.UserSession.ToBeFilledInByBackend (Result Evergreen.V334.Discord.HttpError (List Evergreen.V334.Discord.Role)))
    | ExpandGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | CollapseGuild (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    | HideLog (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    | UnhideLog (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    | DisconnectClient Evergreen.V334.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V334.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V334.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V334.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V334.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V334.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type CloudflareEgressStatus
    = EgressNotRequested
    | LoadingEgress
    | LoadedEgress Int
    | FailedToLoadEgress Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V334.Editable.Model
    , publicVapidKey : Evergreen.V334.Editable.Model
    , privateVapidKey : Evergreen.V334.Editable.Model
    , openRouterKey : Evergreen.V334.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V334.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V334.Editable.Model
    , cloudflareAccountId : Evergreen.V334.Editable.Model
    , cloudflareAnalyticsApiToken : Evergreen.V334.Editable.Model
    , postmarkKey : Evergreen.V334.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V334.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
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
