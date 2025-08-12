module Evergreen.V24.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V24.Id
import Evergreen.V24.LocalState
import Evergreen.V24.NonemptyDict
import Evergreen.V24.Pagination
import Evergreen.V24.Table
import Evergreen.V24.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V24.NonemptyDict.NonemptyDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V24.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
        }
    | ExpandSection Evergreen.V24.User.AdminUiSection
    | CollapseSection Evergreen.V24.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V24.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
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
    { table : Evergreen.V24.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V24.Pagination.Pagination Evergreen.V24.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V24.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V24.User.AdminUiSection
    | PressedExpandSection Evergreen.V24.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V24.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V24.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V24.Pagination.ToFrontend Evergreen.V24.LocalState.LogWithTime)
