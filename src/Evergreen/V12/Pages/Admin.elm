module Evergreen.V12.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V12.Id
import Evergreen.V12.LocalState
import Evergreen.V12.NonemptyDict
import Evergreen.V12.Pagination
import Evergreen.V12.Table
import Evergreen.V12.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V12.NonemptyDict.NonemptyDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
        }
    | ExpandSection Evergreen.V12.User.AdminUiSection
    | CollapseSection Evergreen.V12.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
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
    { table : Evergreen.V12.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V12.Pagination.Pagination Evergreen.V12.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V12.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V12.User.AdminUiSection
    | PressedExpandSection Evergreen.V12.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V12.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V12.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V12.Pagination.ToFrontend Evergreen.V12.LocalState.LogWithTime)
