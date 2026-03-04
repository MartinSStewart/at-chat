module Evergreen.V130.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V130.Discord.Id
import Evergreen.V130.Editable
import Evergreen.V130.Id
import Evergreen.V130.LocalState
import Evergreen.V130.NonemptyDict
import Evergreen.V130.Pagination
import Evergreen.V130.Slack
import Evergreen.V130.Table
import Evergreen.V130.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V130.NonemptyDict.NonemptyDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V130.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V130.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) Evergreen.V130.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) Evergreen.V130.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
        }
    | ExpandSection Evergreen.V130.User.AdminUiSection
    | CollapseSection Evergreen.V130.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V130.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V130.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | CollapseGuild (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
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
    { table : Evergreen.V130.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
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
    , logs : Evergreen.V130.Pagination.Pagination Evergreen.V130.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V130.Editable.Model
    , publicVapidKey : Evergreen.V130.Editable.Model
    , privateVapidKey : Evergreen.V130.Editable.Model
    , openRouterKey : Evergreen.V130.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V130.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V130.User.AdminUiSection
    | PressedExpandSection Evergreen.V130.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V130.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V130.Editable.Msg (Maybe Evergreen.V130.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V130.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V130.Editable.Msg Evergreen.V130.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V130.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V130.Pagination.ToBackend
    | ExportBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V130.Pagination.ToFrontend Evergreen.V130.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
