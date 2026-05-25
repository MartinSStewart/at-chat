module Evergreen.V251.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V251.Cloudflare
import Evergreen.V251.Discord
import Evergreen.V251.Editable
import Evergreen.V251.Id
import Evergreen.V251.LocalState
import Evergreen.V251.NonemptyDict
import Evergreen.V251.Pagination
import Evergreen.V251.Postmark
import Evergreen.V251.SessionIdHash
import Evergreen.V251.Slack
import Evergreen.V251.Table
import Evergreen.V251.ToBackendLog
import Evergreen.V251.User
import Evergreen.V251.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V251.NonemptyDict.NonemptyDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V251.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V251.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V251.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V251.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V251.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) Evergreen.V251.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V251.Pagination.Pagination Evergreen.V251.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V251.SessionIdHash.SessionIdHash (Evergreen.V251.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V251.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V251.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V251.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
        }
    | ExpandSection Evergreen.V251.User.AdminUiSection
    | CollapseSection Evergreen.V251.User.AdminUiSection
    | LogPageChanged (Evergreen.V251.Id.Id Evergreen.V251.Pagination.PageId) (Evergreen.V251.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V251.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V251.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V251.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V251.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V251.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V251.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | DeleteGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | RestoreGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | CollapseGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | HideLog (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    | UnhideLog (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    | DisconnectClient Evergreen.V251.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V251.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V251.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
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


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V251.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V251.Editable.Model
    , publicVapidKey : Evergreen.V251.Editable.Model
    , privateVapidKey : Evergreen.V251.Editable.Model
    , openRouterKey : Evergreen.V251.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V251.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V251.Editable.Model
    , postmarkKey : Evergreen.V251.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V251.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V251.Id.Id Evergreen.V251.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V251.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V251.User.AdminUiSection
    | PressedExpandSection Evergreen.V251.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V251.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V251.Editable.Msg (Maybe Evergreen.V251.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V251.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V251.Editable.Msg Evergreen.V251.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V251.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V251.Editable.Msg (Maybe Evergreen.V251.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V251.Editable.Msg (Maybe Evergreen.V251.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V251.Editable.Msg Evergreen.V251.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V251.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V251.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V251.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V251.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
