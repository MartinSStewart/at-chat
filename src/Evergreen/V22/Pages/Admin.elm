module Evergreen.V22.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V22.Id
import Evergreen.V22.LocalState
import Evergreen.V22.NonemptyDict
import Evergreen.V22.Pagination
import Evergreen.V22.Table
import Evergreen.V22.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V22.NonemptyDict.NonemptyDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
        }
    | ExpandSection Evergreen.V22.User.AdminUiSection
    | CollapseSection Evergreen.V22.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
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
    { table : Evergreen.V22.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V22.Pagination.Pagination Evergreen.V22.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V22.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V22.User.AdminUiSection
    | PressedExpandSection Evergreen.V22.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V22.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V22.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V22.Pagination.ToFrontend Evergreen.V22.LocalState.LogWithTime)
