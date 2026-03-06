module Evergreen.V144.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V144.Discord
import Evergreen.V144.Editable
import Evergreen.V144.Id
import Evergreen.V144.LocalState
import Evergreen.V144.NonemptyDict
import Evergreen.V144.Pagination
import Evergreen.V144.Slack
import Evergreen.V144.Table
import Evergreen.V144.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V144.NonemptyDict.NonemptyDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V144.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V144.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) Evergreen.V144.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) Evergreen.V144.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
        }
    | ExpandSection Evergreen.V144.User.AdminUiSection
    | CollapseSection Evergreen.V144.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V144.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V144.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    | DeleteGuild (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | CollapseGuild (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
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
    { table : Evergreen.V144.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V144.Pagination.Pagination Evergreen.V144.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V144.Editable.Model
    , publicVapidKey : Evergreen.V144.Editable.Model
    , privateVapidKey : Evergreen.V144.Editable.Model
    , openRouterKey : Evergreen.V144.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V144.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V144.User.AdminUiSection
    | PressedExpandSection Evergreen.V144.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V144.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V144.Editable.Msg (Maybe Evergreen.V144.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V144.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V144.Editable.Msg Evergreen.V144.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V144.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V144.Pagination.ToBackend
    | ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V144.Pagination.ToFrontend Evergreen.V144.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
