module Evergreen.V15.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V15.Id
import Evergreen.V15.LocalState
import Evergreen.V15.NonemptyDict
import Evergreen.V15.Pagination
import Evergreen.V15.Table
import Evergreen.V15.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V15.NonemptyDict.NonemptyDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V15.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
        }
    | ExpandSection Evergreen.V15.User.AdminUiSection
    | CollapseSection Evergreen.V15.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V15.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
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
    { table : Evergreen.V15.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V15.Pagination.Pagination Evergreen.V15.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V15.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V15.User.AdminUiSection
    | PressedExpandSection Evergreen.V15.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V15.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V15.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V15.Pagination.ToFrontend Evergreen.V15.LocalState.LogWithTime)
