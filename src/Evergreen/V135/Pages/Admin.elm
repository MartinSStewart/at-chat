module Evergreen.V135.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V135.Discord.Id
import Evergreen.V135.Editable
import Evergreen.V135.Id
import Evergreen.V135.LocalState
import Evergreen.V135.NonemptyDict
import Evergreen.V135.Pagination
import Evergreen.V135.Slack
import Evergreen.V135.Table
import Evergreen.V135.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V135.NonemptyDict.NonemptyDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V135.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V135.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) Evergreen.V135.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
        }
    | ExpandSection Evergreen.V135.User.AdminUiSection
    | CollapseSection Evergreen.V135.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V135.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V135.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | CollapseGuild (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
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
    { table : Evergreen.V135.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
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
    , logs : Evergreen.V135.Pagination.Pagination Evergreen.V135.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V135.Editable.Model
    , publicVapidKey : Evergreen.V135.Editable.Model
    , privateVapidKey : Evergreen.V135.Editable.Model
    , openRouterKey : Evergreen.V135.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V135.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V135.User.AdminUiSection
    | PressedExpandSection Evergreen.V135.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V135.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V135.Editable.Msg (Maybe Evergreen.V135.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V135.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V135.Editable.Msg Evergreen.V135.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V135.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V135.Pagination.ToBackend
    | ExportBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V135.Pagination.ToFrontend Evergreen.V135.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
