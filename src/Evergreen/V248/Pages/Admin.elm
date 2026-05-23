module Evergreen.V248.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V248.Discord
import Evergreen.V248.Editable
import Evergreen.V248.Id
import Evergreen.V248.LocalState
import Evergreen.V248.NonemptyDict
import Evergreen.V248.Pagination
import Evergreen.V248.Postmark
import Evergreen.V248.SessionIdHash
import Evergreen.V248.Slack
import Evergreen.V248.Table
import Evergreen.V248.ToBackendLog
import Evergreen.V248.User
import Evergreen.V248.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V248.NonemptyDict.NonemptyDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V248.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V248.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V248.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) Evergreen.V248.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V248.Pagination.Pagination Evergreen.V248.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V248.SessionIdHash.SessionIdHash (Evergreen.V248.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V248.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V248.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V248.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
        }
    | ExpandSection Evergreen.V248.User.AdminUiSection
    | CollapseSection Evergreen.V248.User.AdminUiSection
    | LogPageChanged (Evergreen.V248.Id.Id Evergreen.V248.Pagination.PageId) (Evergreen.V248.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V248.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V248.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V248.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V248.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | DeleteGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | RestoreGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | CollapseGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | HideLog (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    | UnhideLog (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    | DisconnectClient Evergreen.V248.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V248.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
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
    { table : Evergreen.V248.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
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


type alias Model =
    { highlightLog : Maybe (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V248.Editable.Model
    , publicVapidKey : Evergreen.V248.Editable.Model
    , privateVapidKey : Evergreen.V248.Editable.Model
    , openRouterKey : Evergreen.V248.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V248.Editable.Model
    , postmarkKey : Evergreen.V248.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , websocketCloseEventsPage : Int
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V248.Id.Id Evergreen.V248.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V248.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V248.User.AdminUiSection
    | PressedExpandSection Evergreen.V248.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V248.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V248.Editable.Msg (Maybe Evergreen.V248.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V248.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V248.Editable.Msg Evergreen.V248.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V248.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V248.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V248.Editable.Msg Evergreen.V248.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V248.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
