module Evergreen.V42.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V42.Id
import Evergreen.V42.LocalState
import Evergreen.V42.NonemptyDict
import Evergreen.V42.Pagination
import Evergreen.V42.Table
import Evergreen.V42.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V42.NonemptyDict.NonemptyDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V42.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V42.LocalState.PrivateVapidKey
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
        }
    | ExpandSection Evergreen.V42.User.AdminUiSection
    | CollapseSection Evergreen.V42.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V42.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V42.LocalState.PrivateVapidKey
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
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
    { table : Evergreen.V42.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V42.Pagination.Pagination Evergreen.V42.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V42.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V42.User.AdminUiSection
    | PressedExpandSection Evergreen.V42.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V42.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V42.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V42.Pagination.ToFrontend Evergreen.V42.LocalState.LogWithTime)
