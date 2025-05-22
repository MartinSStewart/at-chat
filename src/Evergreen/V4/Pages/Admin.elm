module Evergreen.V4.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V4.Id
import Evergreen.V4.LocalState
import Evergreen.V4.NonemptyDict
import Evergreen.V4.Pagination
import Evergreen.V4.Table
import Evergreen.V4.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V4.NonemptyDict.NonemptyDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
        }
    | ExpandSection Evergreen.V4.User.AdminUiSection
    | CollapseSection Evergreen.V4.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
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
    { table : Evergreen.V4.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V4.Pagination.Pagination Evergreen.V4.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V4.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V4.User.AdminUiSection
    | PressedExpandSection Evergreen.V4.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V4.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V4.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V4.Pagination.ToFrontend Evergreen.V4.LocalState.LogWithTime)
