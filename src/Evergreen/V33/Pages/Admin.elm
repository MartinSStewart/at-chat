module Evergreen.V33.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V33.Id
import Evergreen.V33.LocalState
import Evergreen.V33.NonemptyDict
import Evergreen.V33.Pagination
import Evergreen.V33.Table
import Evergreen.V33.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V33.NonemptyDict.NonemptyDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V33.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
        }
    | ExpandSection Evergreen.V33.User.AdminUiSection
    | CollapseSection Evergreen.V33.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V33.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
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
    { table : Evergreen.V33.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V33.Pagination.Pagination Evergreen.V33.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V33.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V33.User.AdminUiSection
    | PressedExpandSection Evergreen.V33.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V33.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V33.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V33.Pagination.ToFrontend Evergreen.V33.LocalState.LogWithTime)
