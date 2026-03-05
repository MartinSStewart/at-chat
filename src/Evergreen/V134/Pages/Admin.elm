module Evergreen.V134.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V134.Discord.Id
import Evergreen.V134.Editable
import Evergreen.V134.Id
import Evergreen.V134.LocalState
import Evergreen.V134.NonemptyDict
import Evergreen.V134.Pagination
import Evergreen.V134.Slack
import Evergreen.V134.Table
import Evergreen.V134.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V134.NonemptyDict.NonemptyDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V134.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V134.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) Evergreen.V134.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
        }
    | ExpandSection Evergreen.V134.User.AdminUiSection
    | CollapseSection Evergreen.V134.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V134.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V134.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | CollapseGuild (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
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
    { table : Evergreen.V134.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
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
    , logs : Evergreen.V134.Pagination.Pagination Evergreen.V134.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V134.Editable.Model
    , publicVapidKey : Evergreen.V134.Editable.Model
    , privateVapidKey : Evergreen.V134.Editable.Model
    , openRouterKey : Evergreen.V134.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V134.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V134.User.AdminUiSection
    | PressedExpandSection Evergreen.V134.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V134.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V134.Editable.Msg (Maybe Evergreen.V134.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V134.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V134.Editable.Msg Evergreen.V134.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V134.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V134.Pagination.ToBackend
    | ExportBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V134.Pagination.ToFrontend Evergreen.V134.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
