module Evergreen.V3.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V3.Id
import Evergreen.V3.LocalState
import Evergreen.V3.NonemptyDict
import Evergreen.V3.Pagination
import Evergreen.V3.Table
import Evergreen.V3.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V3.NonemptyDict.NonemptyDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Effect.Time.Posix
    , websocketEnabled : Evergreen.V3.LocalState.IsEnabled
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
        }
    | ExpandSection Evergreen.V3.User.AdminUiSection
    | CollapseSection Evergreen.V3.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool


type UserTableId
    = ExistingUserId (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
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
    { table : Evergreen.V3.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V3.Pagination.Pagination Evergreen.V3.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V3.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V3.User.AdminUiSection
    | PressedExpandSection Evergreen.V3.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V3.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V3.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V3.Pagination.ToFrontend Evergreen.V3.LocalState.LogWithTime)
