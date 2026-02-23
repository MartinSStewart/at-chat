module Evergreen.V119.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V119.Discord.Id
import Evergreen.V119.Id
import Evergreen.V119.LocalState
import Evergreen.V119.NonemptyDict
import Evergreen.V119.NonemptySet
import Evergreen.V119.Pagination
import Evergreen.V119.Slack
import Evergreen.V119.Table
import Evergreen.V119.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V119.NonemptyDict.NonemptyDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V119.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V119.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId)
            { members : Evergreen.V119.NonemptySet.NonemptySet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.LocalState.DiscordUserData_ForAdmin
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
        }
    | ExpandSection Evergreen.V119.User.AdminUiSection
    | CollapseSection Evergreen.V119.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V119.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V119.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
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
    { table : Evergreen.V119.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V119.Pagination.Pagination Evergreen.V119.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V119.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V119.User.AdminUiSection
    | PressedExpandSection Evergreen.V119.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V119.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V119.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V119.Pagination.ToFrontend Evergreen.V119.LocalState.LogWithTime)
