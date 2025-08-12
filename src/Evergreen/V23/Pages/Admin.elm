module Evergreen.V23.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V23.Id
import Evergreen.V23.LocalState
import Evergreen.V23.NonemptyDict
import Evergreen.V23.Pagination
import Evergreen.V23.Table
import Evergreen.V23.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V23.NonemptyDict.NonemptyDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V23.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
        }
    | ExpandSection Evergreen.V23.User.AdminUiSection
    | CollapseSection Evergreen.V23.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V23.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
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
    { table : Evergreen.V23.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V23.Pagination.Pagination Evergreen.V23.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V23.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V23.User.AdminUiSection
    | PressedExpandSection Evergreen.V23.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V23.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V23.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V23.Pagination.ToFrontend Evergreen.V23.LocalState.LogWithTime)
