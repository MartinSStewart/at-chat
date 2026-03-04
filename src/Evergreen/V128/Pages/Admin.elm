module Evergreen.V128.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V128.Discord.Id
import Evergreen.V128.Editable
import Evergreen.V128.Id
import Evergreen.V128.LocalState
import Evergreen.V128.NonemptyDict
import Evergreen.V128.Pagination
import Evergreen.V128.Slack
import Evergreen.V128.Table
import Evergreen.V128.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V128.NonemptyDict.NonemptyDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V128.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V128.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) Evergreen.V128.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) Evergreen.V128.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.LocalState.LoadingDiscordChannel Int)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
        }
    | ExpandSection Evergreen.V128.User.AdminUiSection
    | CollapseSection Evergreen.V128.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V128.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V128.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | CollapseGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
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
    { table : Evergreen.V128.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V128.Pagination.Pagination Evergreen.V128.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V128.Editable.Model
    , publicVapidKey : Evergreen.V128.Editable.Model
    , privateVapidKey : Evergreen.V128.Editable.Model
    , openRouterKey : Evergreen.V128.Editable.Model
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V128.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V128.User.AdminUiSection
    | PressedExpandSection Evergreen.V128.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V128.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V128.Editable.Msg (Maybe Evergreen.V128.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V128.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V128.Editable.Msg Evergreen.V128.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V128.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput


type ToBackend
    = LogPaginationToBackend Evergreen.V128.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V128.Pagination.ToFrontend Evergreen.V128.LocalState.LogWithTime)
