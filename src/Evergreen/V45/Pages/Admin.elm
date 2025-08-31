module Evergreen.V45.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V45.Id
import Evergreen.V45.LocalState
import Evergreen.V45.NonemptyDict
import Evergreen.V45.Pagination
import Evergreen.V45.Table
import Evergreen.V45.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V45.NonemptyDict.NonemptyDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V45.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V45.LocalState.PrivateVapidKey
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
        }
    | ExpandSection Evergreen.V45.User.AdminUiSection
    | CollapseSection Evergreen.V45.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V45.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V45.LocalState.PrivateVapidKey
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
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
    { table : Evergreen.V45.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V45.Pagination.Pagination Evergreen.V45.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V45.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V45.User.AdminUiSection
    | PressedExpandSection Evergreen.V45.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V45.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V45.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V45.Pagination.ToFrontend Evergreen.V45.LocalState.LogWithTime)
