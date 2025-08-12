module Evergreen.V26.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V26.Id
import Evergreen.V26.LocalState
import Evergreen.V26.NonemptyDict
import Evergreen.V26.Pagination
import Evergreen.V26.Table
import Evergreen.V26.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V26.NonemptyDict.NonemptyDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V26.LocalState.DiscordBotToken
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
        }
    | ExpandSection Evergreen.V26.User.AdminUiSection
    | CollapseSection Evergreen.V26.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V26.LocalState.DiscordBotToken)


type UserTableId
    = ExistingUserId (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
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
    { table : Evergreen.V26.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V26.Pagination.Pagination Evergreen.V26.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V26.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V26.User.AdminUiSection
    | PressedExpandSection Evergreen.V26.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V26.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V26.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V26.Pagination.ToFrontend Evergreen.V26.LocalState.LogWithTime)
