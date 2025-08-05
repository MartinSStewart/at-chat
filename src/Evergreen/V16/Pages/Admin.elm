module Evergreen.V16.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V16.Id
import Evergreen.V16.LocalState
import Evergreen.V16.NonemptyDict
import Evergreen.V16.Pagination
import Evergreen.V16.Table
import Evergreen.V16.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V16.NonemptyDict.NonemptyDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V16.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
        }
    | ExpandSection Evergreen.V16.User.AdminUiSection
    | CollapseSection Evergreen.V16.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V16.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
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
    { table : Evergreen.V16.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V16.Pagination.Pagination Evergreen.V16.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V16.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V16.User.AdminUiSection
    | PressedExpandSection Evergreen.V16.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V16.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V16.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V16.Pagination.ToFrontend Evergreen.V16.LocalState.LogWithTime)
