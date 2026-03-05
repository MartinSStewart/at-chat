module Evergreen.V137.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V137.Discord.Id
import Evergreen.V137.Editable
import Evergreen.V137.Id
import Evergreen.V137.LocalState
import Evergreen.V137.NonemptyDict
import Evergreen.V137.Pagination
import Evergreen.V137.Slack
import Evergreen.V137.Table
import Evergreen.V137.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V137.NonemptyDict.NonemptyDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V137.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V137.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) Evergreen.V137.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
        }
    | ExpandSection Evergreen.V137.User.AdminUiSection
    | CollapseSection Evergreen.V137.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V137.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V137.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | CollapseGuild (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
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
    { table : Evergreen.V137.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
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
    , logs : Evergreen.V137.Pagination.Pagination Evergreen.V137.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V137.Editable.Model
    , publicVapidKey : Evergreen.V137.Editable.Model
    , privateVapidKey : Evergreen.V137.Editable.Model
    , openRouterKey : Evergreen.V137.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V137.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V137.User.AdminUiSection
    | PressedExpandSection Evergreen.V137.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V137.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V137.Editable.Msg (Maybe Evergreen.V137.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V137.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V137.Editable.Msg Evergreen.V137.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V137.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V137.Pagination.ToBackend
    | ExportBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V137.Pagination.ToFrontend Evergreen.V137.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
