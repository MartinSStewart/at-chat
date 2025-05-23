module Evergreen.V7.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V7.Id
import Evergreen.V7.LocalState
import Evergreen.V7.NonemptyDict
import Evergreen.V7.Pagination
import Evergreen.V7.Table
import Evergreen.V7.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V7.NonemptyDict.NonemptyDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
        }
    | ExpandSection Evergreen.V7.User.AdminUiSection
    | CollapseSection Evergreen.V7.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
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
    { table : Evergreen.V7.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V7.Pagination.Pagination Evergreen.V7.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V7.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V7.User.AdminUiSection
    | PressedExpandSection Evergreen.V7.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V7.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V7.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V7.Pagination.ToFrontend Evergreen.V7.LocalState.LogWithTime)
