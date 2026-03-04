module Evergreen.V125.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V125.Discord.Id
import Evergreen.V125.Editable
import Evergreen.V125.Id
import Evergreen.V125.LocalState
import Evergreen.V125.NonemptyDict
import Evergreen.V125.Pagination
import Evergreen.V125.Slack
import Evergreen.V125.Table
import Evergreen.V125.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V125.NonemptyDict.NonemptyDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V125.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V125.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) Evergreen.V125.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.LocalState.AdminData_Guild
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
        }
    | ExpandSection Evergreen.V125.User.AdminUiSection
    | CollapseSection Evergreen.V125.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V125.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V125.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | StartReloadingDiscordChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | ExpandGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | CollapseGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | CollapseDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
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
    { table : Evergreen.V125.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V125.Pagination.Pagination Evergreen.V125.LocalState.LogWithTime
    , slackClientSecret : Evergreen.V125.Editable.Model
    , publicVapidKey : Evergreen.V125.Editable.Model
    , privateVapidKey : Evergreen.V125.Editable.Model
    , openRouterKey : Evergreen.V125.Editable.Model
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V125.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V125.User.AdminUiSection
    | PressedExpandSection Evergreen.V125.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V125.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | PressedExpandGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V125.Editable.Msg (Maybe Evergreen.V125.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V125.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V125.Editable.Msg Evergreen.V125.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V125.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput


type ToBackend
    = LogPaginationToBackend Evergreen.V125.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V125.Pagination.ToFrontend Evergreen.V125.LocalState.LogWithTime)
