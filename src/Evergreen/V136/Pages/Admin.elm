module Evergreen.V136.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V136.Discord.Id
import Evergreen.V136.Editable
import Evergreen.V136.Id
import Evergreen.V136.LocalState
import Evergreen.V136.NonemptyDict
import Evergreen.V136.Pagination
import Evergreen.V136.Slack
import Evergreen.V136.Table
import Evergreen.V136.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V136.NonemptyDict.NonemptyDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V136.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V136.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) Evergreen.V136.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
        }
    | ExpandSection Evergreen.V136.User.AdminUiSection
    | CollapseSection Evergreen.V136.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V136.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V136.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | CollapseGuild (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
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
    { table : Evergreen.V136.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
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
    , logs : Evergreen.V136.Pagination.Pagination Evergreen.V136.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V136.Editable.Model
    , publicVapidKey : Evergreen.V136.Editable.Model
    , privateVapidKey : Evergreen.V136.Editable.Model
    , openRouterKey : Evergreen.V136.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V136.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V136.User.AdminUiSection
    | PressedExpandSection Evergreen.V136.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V136.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V136.Editable.Msg (Maybe Evergreen.V136.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V136.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V136.Editable.Msg Evergreen.V136.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V136.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V136.Pagination.ToBackend
    | ExportBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V136.Pagination.ToFrontend Evergreen.V136.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
