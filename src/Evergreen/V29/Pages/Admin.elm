module Evergreen.V29.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V29.Id
import Evergreen.V29.LocalState
import Evergreen.V29.NonemptyDict
import Evergreen.V29.Pagination
import Evergreen.V29.Table
import Evergreen.V29.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V29.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
        }
    | ExpandSection Evergreen.V29.User.AdminUiSection
    | CollapseSection Evergreen.V29.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V29.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
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
    { table : Evergreen.V29.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V29.Pagination.Pagination Evergreen.V29.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V29.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V29.User.AdminUiSection
    | PressedExpandSection Evergreen.V29.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V29.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V29.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V29.Pagination.ToFrontend Evergreen.V29.LocalState.LogWithTime)
