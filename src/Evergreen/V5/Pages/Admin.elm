module Evergreen.V5.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V5.Id
import Evergreen.V5.LocalState
import Evergreen.V5.NonemptyDict
import Evergreen.V5.Pagination
import Evergreen.V5.Table
import Evergreen.V5.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V5.NonemptyDict.NonemptyDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
        }
    | ExpandSection Evergreen.V5.User.AdminUiSection
    | CollapseSection Evergreen.V5.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
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
    { table : Evergreen.V5.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V5.Pagination.Pagination Evergreen.V5.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V5.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V5.User.AdminUiSection
    | PressedExpandSection Evergreen.V5.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V5.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V5.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V5.Pagination.ToFrontend Evergreen.V5.LocalState.LogWithTime)
