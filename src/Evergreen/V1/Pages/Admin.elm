module Evergreen.V1.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V1.Id
import Evergreen.V1.LocalState
import Evergreen.V1.NonemptyDict
import Evergreen.V1.Pagination
import Evergreen.V1.Table
import Evergreen.V1.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V1.NonemptyDict.NonemptyDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
        }
    | ExpandSection Evergreen.V1.User.AdminUiSection
    | CollapseSection Evergreen.V1.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
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
    { table : Evergreen.V1.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V1.Pagination.Pagination Evergreen.V1.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V1.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V1.User.AdminUiSection
    | PressedExpandSection Evergreen.V1.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V1.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V1.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V1.Pagination.ToFrontend Evergreen.V1.LocalState.LogWithTime)
