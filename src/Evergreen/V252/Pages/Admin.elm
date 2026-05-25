module Evergreen.V252.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V252.Cloudflare
import Evergreen.V252.Discord
import Evergreen.V252.Editable
import Evergreen.V252.Id
import Evergreen.V252.LocalState
import Evergreen.V252.NonemptyDict
import Evergreen.V252.Pagination
import Evergreen.V252.Postmark
import Evergreen.V252.SessionIdHash
import Evergreen.V252.Slack
import Evergreen.V252.Table
import Evergreen.V252.ToBackendLog
import Evergreen.V252.User
import Evergreen.V252.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V252.NonemptyDict.NonemptyDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V252.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V252.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V252.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V252.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V252.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) Evergreen.V252.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V252.Pagination.Pagination Evergreen.V252.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V252.SessionIdHash.SessionIdHash (Evergreen.V252.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V252.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V252.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V252.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
        }
    | ExpandSection Evergreen.V252.User.AdminUiSection
    | CollapseSection Evergreen.V252.User.AdminUiSection
    | LogPageChanged (Evergreen.V252.Id.Id Evergreen.V252.Pagination.PageId) (Evergreen.V252.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V252.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V252.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V252.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V252.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V252.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V252.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | DeleteGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | RestoreGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | CollapseGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | HideLog (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    | UnhideLog (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    | DisconnectClient Evergreen.V252.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V252.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
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
    { table : Evergreen.V252.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
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
    | LoadedRealtimeSessionInfo Evergreen.V252.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V252.Editable.Model
    , publicVapidKey : Evergreen.V252.Editable.Model
    , privateVapidKey : Evergreen.V252.Editable.Model
    , openRouterKey : Evergreen.V252.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V252.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V252.Editable.Model
    , postmarkKey : Evergreen.V252.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V252.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V252.Id.Id Evergreen.V252.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V252.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V252.User.AdminUiSection
    | PressedExpandSection Evergreen.V252.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V252.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V252.Editable.Msg (Maybe Evergreen.V252.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V252.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V252.Editable.Msg Evergreen.V252.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V252.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V252.Editable.Msg (Maybe Evergreen.V252.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V252.Editable.Msg (Maybe Evergreen.V252.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V252.Editable.Msg Evergreen.V252.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V252.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V252.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V252.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V252.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
