module Evergreen.V146.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V146.Discord
import Evergreen.V146.Editable
import Evergreen.V146.Id
import Evergreen.V146.LocalState
import Evergreen.V146.NonemptyDict
import Evergreen.V146.Pagination
import Evergreen.V146.Slack
import Evergreen.V146.Table
import Evergreen.V146.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V146.NonemptyDict.NonemptyDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V146.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V146.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) Evergreen.V146.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) Evergreen.V146.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V146.Pagination.Pagination Evergreen.V146.LocalState.LogWithTime
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
        }
    | ExpandSection Evergreen.V146.User.AdminUiSection
    | CollapseSection Evergreen.V146.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V146.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V146.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    | DeleteGuild (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | CollapseGuild (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    | HideLog Int


type UserTableId
    = ExistingUserId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
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
    { table : Evergreen.V146.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
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
    , slackClientSecret : Evergreen.V146.Editable.Model
    , publicVapidKey : Evergreen.V146.Editable.Model
    , privateVapidKey : Evergreen.V146.Editable.Model
    , openRouterKey : Evergreen.V146.Editable.Model
    , importBackendStatus : ImportBackendStatus
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V146.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V146.User.AdminUiSection
    | PressedExpandSection Evergreen.V146.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V146.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V146.Editable.Msg (Maybe Evergreen.V146.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V146.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V146.Editable.Msg Evergreen.V146.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V146.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog Int


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
