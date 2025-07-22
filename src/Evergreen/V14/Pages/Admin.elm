module Evergreen.V14.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V14.Id
import Evergreen.V14.LocalState
import Evergreen.V14.NonemptyDict
import Evergreen.V14.Pagination
import Evergreen.V14.Table
import Evergreen.V14.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V14.NonemptyDict.NonemptyDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Effect.Time.Posix
    , websocketEnabled : Evergreen.V14.LocalState.IsEnabled
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
        }
    | ExpandSection Evergreen.V14.User.AdminUiSection
    | CollapseSection Evergreen.V14.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
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
    { table : Evergreen.V14.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V14.Pagination.Pagination Evergreen.V14.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V14.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V14.User.AdminUiSection
    | PressedExpandSection Evergreen.V14.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V14.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V14.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V14.Pagination.ToFrontend Evergreen.V14.LocalState.LogWithTime)
