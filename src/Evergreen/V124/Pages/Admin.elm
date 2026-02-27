module Evergreen.V124.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V124.Discord.Id
import Evergreen.V124.GuildName
import Evergreen.V124.Id
import Evergreen.V124.LocalState
import Evergreen.V124.NonemptyDict
import Evergreen.V124.NonemptySet
import Evergreen.V124.Pagination
import Evergreen.V124.Slack
import Evergreen.V124.Table
import Evergreen.V124.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V124.NonemptyDict.NonemptyDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V124.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V124.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
            { members : Evergreen.V124.NonemptySet.NonemptySet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.LocalState.DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
            { name : Evergreen.V124.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
            }
    , guilds :
        SeqDict.SeqDict
            (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
            { name : Evergreen.V124.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            }
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
        }
    | ExpandSection Evergreen.V124.User.AdminUiSection
    | CollapseSection Evergreen.V124.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V124.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V124.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
    | DeleteGuild (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)


type UserTableId
    = ExistingUserId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
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
    { table : Evergreen.V124.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V124.Pagination.Pagination Evergreen.V124.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V124.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V124.User.AdminUiSection
    | PressedExpandSection Evergreen.V124.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V124.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)


type ToBackend
    = LogPaginationToBackend Evergreen.V124.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V124.Pagination.ToFrontend Evergreen.V124.LocalState.LogWithTime)
