module Evergreen.V25.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V25.Id
import Evergreen.V25.LocalState
import Evergreen.V25.NonemptyDict
import Evergreen.V25.Pagination
import Evergreen.V25.Table
import Evergreen.V25.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V25.NonemptyDict.NonemptyDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
        }
    | ExpandSection Evergreen.V25.User.AdminUiSection
    | CollapseSection Evergreen.V25.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
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
    { table : Evergreen.V25.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V25.Pagination.Pagination Evergreen.V25.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V25.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V25.User.AdminUiSection
    | PressedExpandSection Evergreen.V25.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V25.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V25.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V25.Pagination.ToFrontend Evergreen.V25.LocalState.LogWithTime)
