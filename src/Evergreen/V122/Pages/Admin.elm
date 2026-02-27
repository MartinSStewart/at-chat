module Evergreen.V122.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V122.Discord.Id
import Evergreen.V122.GuildName
import Evergreen.V122.Id
import Evergreen.V122.LocalState
import Evergreen.V122.NonemptyDict
import Evergreen.V122.NonemptySet
import Evergreen.V122.Pagination
import Evergreen.V122.Slack
import Evergreen.V122.Table
import Evergreen.V122.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V122.NonemptyDict.NonemptyDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V122.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V122.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)
            { members : Evergreen.V122.NonemptySet.NonemptySet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.LocalState.DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId)
            { name : Evergreen.V122.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
        }
    | ExpandSection Evergreen.V122.User.AdminUiSection
    | CollapseSection Evergreen.V122.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V122.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V122.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)


type UserTableId
    = ExistingUserId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
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
    { table : Evergreen.V122.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V122.Pagination.Pagination Evergreen.V122.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V122.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V122.User.AdminUiSection
    | PressedExpandSection Evergreen.V122.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V122.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)


type ToBackend
    = LogPaginationToBackend Evergreen.V122.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V122.Pagination.ToFrontend Evergreen.V122.LocalState.LogWithTime)
