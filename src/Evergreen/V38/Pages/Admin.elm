module Evergreen.V38.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V38.Id
import Evergreen.V38.LocalState
import Evergreen.V38.NonemptyDict
import Evergreen.V38.Pagination
import Evergreen.V38.Table
import Evergreen.V38.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V38.NonemptyDict.NonemptyDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V38.LocalState.DiscordBotToken
    , privateVapidKey : String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
        }
    | ExpandSection Evergreen.V38.User.AdminUiSection
    | CollapseSection Evergreen.V38.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V38.LocalState.DiscordBotToken)
    | SetPrivateVapidKey String
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
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
    { table : Evergreen.V38.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V38.Pagination.Pagination Evergreen.V38.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V38.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V38.User.AdminUiSection
    | PressedExpandSection Evergreen.V38.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V38.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V38.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V38.Pagination.ToFrontend Evergreen.V38.LocalState.LogWithTime)
