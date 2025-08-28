module Evergreen.V39.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V39.Id
import Evergreen.V39.LocalState
import Evergreen.V39.NonemptyDict
import Evergreen.V39.Pagination
import Evergreen.V39.Table
import Evergreen.V39.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V39.NonemptyDict.NonemptyDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V39.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V39.LocalState.PrivateVapidKey
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
        }
    | ExpandSection Evergreen.V39.User.AdminUiSection
    | CollapseSection Evergreen.V39.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V39.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V39.LocalState.PrivateVapidKey
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
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
    { table : Evergreen.V39.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V39.Pagination.Pagination Evergreen.V39.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V39.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V39.User.AdminUiSection
    | PressedExpandSection Evergreen.V39.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V39.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V39.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V39.Pagination.ToFrontend Evergreen.V39.LocalState.LogWithTime)
