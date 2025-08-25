module Evergreen.V30.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V30.Id
import Evergreen.V30.LocalState
import Evergreen.V30.NonemptyDict
import Evergreen.V30.Pagination
import Evergreen.V30.Table
import Evergreen.V30.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V30.NonemptyDict.NonemptyDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V30.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
        }
    | ExpandSection Evergreen.V30.User.AdminUiSection
    | CollapseSection Evergreen.V30.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V30.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
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
    { table : Evergreen.V30.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V30.Pagination.Pagination Evergreen.V30.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V30.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V30.User.AdminUiSection
    | PressedExpandSection Evergreen.V30.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V30.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V30.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V30.Pagination.ToFrontend Evergreen.V30.LocalState.LogWithTime)
