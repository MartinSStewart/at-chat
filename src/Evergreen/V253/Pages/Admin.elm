module Evergreen.V253.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V253.Cloudflare
import Evergreen.V253.Discord
import Evergreen.V253.Editable
import Evergreen.V253.Id
import Evergreen.V253.LocalState
import Evergreen.V253.NonemptyDict
import Evergreen.V253.Pagination
import Evergreen.V253.Postmark
import Evergreen.V253.SessionIdHash
import Evergreen.V253.Slack
import Evergreen.V253.Table
import Evergreen.V253.ToBackendLog
import Evergreen.V253.User
import Evergreen.V253.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V253.NonemptyDict.NonemptyDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V253.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V253.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V253.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V253.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V253.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) Evergreen.V253.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V253.Pagination.Pagination Evergreen.V253.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V253.SessionIdHash.SessionIdHash (Evergreen.V253.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V253.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V253.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V253.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
        }
    | ExpandSection Evergreen.V253.User.AdminUiSection
    | CollapseSection Evergreen.V253.User.AdminUiSection
    | LogPageChanged (Evergreen.V253.Id.Id Evergreen.V253.Pagination.PageId) (Evergreen.V253.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V253.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V253.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V253.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V253.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V253.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V253.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | DeleteGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | RestoreGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | CollapseGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | HideLog (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    | UnhideLog (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    | DisconnectClient Evergreen.V253.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V253.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
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
    { table : Evergreen.V253.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
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
    | LoadedRealtimeSessionInfo Evergreen.V253.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V253.Editable.Model
    , publicVapidKey : Evergreen.V253.Editable.Model
    , privateVapidKey : Evergreen.V253.Editable.Model
    , openRouterKey : Evergreen.V253.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V253.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V253.Editable.Model
    , postmarkKey : Evergreen.V253.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe (SeqSet.SeqSet (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId))
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V253.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset (SeqSet.SeqSet (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId))
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V253.Id.Id Evergreen.V253.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V253.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V253.User.AdminUiSection
    | PressedExpandSection Evergreen.V253.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V253.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V253.Editable.Msg (Maybe Evergreen.V253.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V253.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V253.Editable.Msg Evergreen.V253.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V253.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V253.Editable.Msg (Maybe Evergreen.V253.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V253.Editable.Msg (Maybe Evergreen.V253.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V253.Editable.Msg Evergreen.V253.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V253.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V253.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V253.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V253.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
