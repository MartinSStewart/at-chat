module Evergreen.V41.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V41.Id
import Evergreen.V41.LocalState
import Evergreen.V41.NonemptyDict
import Evergreen.V41.Pagination
import Evergreen.V41.Table
import Evergreen.V41.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V41.NonemptyDict.NonemptyDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V41.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V41.LocalState.PrivateVapidKey
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
        }
    | ExpandSection Evergreen.V41.User.AdminUiSection
    | CollapseSection Evergreen.V41.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V41.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V41.LocalState.PrivateVapidKey
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
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
    { table : Evergreen.V41.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V41.Pagination.Pagination Evergreen.V41.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V41.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V41.User.AdminUiSection
    | PressedExpandSection Evergreen.V41.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V41.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V41.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V41.Pagination.ToFrontend Evergreen.V41.LocalState.LogWithTime)
