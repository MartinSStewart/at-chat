module Evergreen.V77.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V77.Id
import Evergreen.V77.LocalState
import Evergreen.V77.NonemptyDict
import Evergreen.V77.Pagination
import Evergreen.V77.Slack
import Evergreen.V77.Table
import Evergreen.V77.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V77.NonemptyDict.NonemptyDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V77.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V77.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V77.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
        }
    | ExpandSection Evergreen.V77.User.AdminUiSection
    | CollapseSection Evergreen.V77.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V77.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V77.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V77.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
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
    { table : Evergreen.V77.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V77.Pagination.Pagination Evergreen.V77.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V77.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V77.User.AdminUiSection
    | PressedExpandSection Evergreen.V77.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V77.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V77.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V77.Pagination.ToFrontend Evergreen.V77.LocalState.LogWithTime)
