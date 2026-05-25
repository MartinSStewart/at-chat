module Evergreen.V250.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V250.Discord
import Evergreen.V250.Editable
import Evergreen.V250.Id
import Evergreen.V250.LocalState
import Evergreen.V250.NonemptyDict
import Evergreen.V250.Pagination
import Evergreen.V250.Postmark
import Evergreen.V250.SessionIdHash
import Evergreen.V250.Slack
import Evergreen.V250.Table
import Evergreen.V250.ToBackendLog
import Evergreen.V250.User
import Evergreen.V250.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V250.NonemptyDict.NonemptyDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V250.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V250.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V250.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) Evergreen.V250.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V250.Pagination.Pagination Evergreen.V250.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V250.SessionIdHash.SessionIdHash (Evergreen.V250.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V250.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V250.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V250.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
        }
    | ExpandSection Evergreen.V250.User.AdminUiSection
    | CollapseSection Evergreen.V250.User.AdminUiSection
    | LogPageChanged (Evergreen.V250.Id.Id Evergreen.V250.Pagination.PageId) (Evergreen.V250.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V250.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V250.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V250.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V250.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | DeleteGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | RestoreGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | CollapseGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | HideLog (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    | UnhideLog (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    | DisconnectClient Evergreen.V250.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V250.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
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
    { table : Evergreen.V250.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V250.Editable.Model
    , publicVapidKey : Evergreen.V250.Editable.Model
    , privateVapidKey : Evergreen.V250.Editable.Model
    , openRouterKey : Evergreen.V250.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V250.Editable.Model
    , postmarkKey : Evergreen.V250.Editable.Model
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
    = PressedLogPage (Evergreen.V250.Id.Id Evergreen.V250.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V250.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V250.User.AdminUiSection
    | PressedExpandSection Evergreen.V250.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V250.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V250.Editable.Msg (Maybe Evergreen.V250.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V250.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V250.Editable.Msg Evergreen.V250.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V250.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V250.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V250.Editable.Msg Evergreen.V250.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V250.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
