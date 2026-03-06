module Evergreen.V138.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V138.Discord.Id
import Evergreen.V138.Editable
import Evergreen.V138.Id
import Evergreen.V138.LocalState
import Evergreen.V138.NonemptyDict
import Evergreen.V138.Pagination
import Evergreen.V138.Slack
import Evergreen.V138.Table
import Evergreen.V138.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V138.NonemptyDict.NonemptyDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V138.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V138.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) Evergreen.V138.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
        }
    | ExpandSection Evergreen.V138.User.AdminUiSection
    | CollapseSection Evergreen.V138.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V138.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V138.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | CollapseGuild (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
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
    { table : Evergreen.V138.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
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
    , logs : Evergreen.V138.Pagination.Pagination Evergreen.V138.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V138.Editable.Model
    , publicVapidKey : Evergreen.V138.Editable.Model
    , privateVapidKey : Evergreen.V138.Editable.Model
    , openRouterKey : Evergreen.V138.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V138.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V138.User.AdminUiSection
    | PressedExpandSection Evergreen.V138.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V138.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V138.Editable.Msg (Maybe Evergreen.V138.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V138.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V138.Editable.Msg Evergreen.V138.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V138.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes


type ToBackend
    = LogPaginationToBackend Evergreen.V138.Pagination.ToBackend
    | ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V138.Pagination.ToFrontend Evergreen.V138.LocalState.LogWithTime)
    | ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
