module Evergreen.V27.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V27.Id
import Evergreen.V27.LocalState
import Evergreen.V27.NonemptyDict
import Evergreen.V27.Pagination
import Evergreen.V27.Table
import Evergreen.V27.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
        }
    | ExpandSection Evergreen.V27.User.AdminUiSection
    | CollapseSection Evergreen.V27.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
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
    { table : Evergreen.V27.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V27.Pagination.Pagination Evergreen.V27.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V27.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V27.User.AdminUiSection
    | PressedExpandSection Evergreen.V27.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V27.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V27.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V27.Pagination.ToFrontend Evergreen.V27.LocalState.LogWithTime)
