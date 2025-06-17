module Evergreen.V32.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V32.Id
import Evergreen.V32.LocalState
import Evergreen.V32.NonemptyDict
import Evergreen.V32.Pagination
import Evergreen.V32.Table
import Evergreen.V32.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V32.NonemptyDict.NonemptyDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
        }
    | ExpandSection Evergreen.V32.User.AdminUiSection
    | CollapseSection Evergreen.V32.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
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
    { table : Evergreen.V32.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V32.Pagination.Pagination Evergreen.V32.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V32.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V32.User.AdminUiSection
    | PressedExpandSection Evergreen.V32.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V32.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V32.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V32.Pagination.ToFrontend Evergreen.V32.LocalState.LogWithTime)
