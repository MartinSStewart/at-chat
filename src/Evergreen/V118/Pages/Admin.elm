module Evergreen.V118.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V118.Id
import Evergreen.V118.LocalState
import Evergreen.V118.NonemptyDict
import Evergreen.V118.Pagination
import Evergreen.V118.Slack
import Evergreen.V118.Table
import Evergreen.V118.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V118.NonemptyDict.NonemptyDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V118.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V118.Slack.ClientSecret
    , openRouterKey : Maybe String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
        }
    | ExpandSection Evergreen.V118.User.AdminUiSection
    | CollapseSection Evergreen.V118.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V118.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V118.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
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
    { table : Evergreen.V118.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V118.Pagination.Pagination Evergreen.V118.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V118.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V118.User.AdminUiSection
    | PressedExpandSection Evergreen.V118.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V118.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V118.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V118.Pagination.ToFrontend Evergreen.V118.LocalState.LogWithTime)
