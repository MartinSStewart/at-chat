module Evergreen.V46.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V46.Id
import Evergreen.V46.LocalState
import Evergreen.V46.NonemptyDict
import Evergreen.V46.Pagination
import Evergreen.V46.Table
import Evergreen.V46.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V46.NonemptyDict.NonemptyDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V46.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V46.LocalState.PrivateVapidKey
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
        }
    | ExpandSection Evergreen.V46.User.AdminUiSection
    | CollapseSection Evergreen.V46.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V46.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V46.LocalState.PrivateVapidKey
    | SetPublicVapidKey String


type UserTableId
    = ExistingUserId (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
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
    { table : Evergreen.V46.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V46.Pagination.Pagination Evergreen.V46.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V46.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V46.User.AdminUiSection
    | PressedExpandSection Evergreen.V46.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V46.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V46.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V46.Pagination.ToFrontend Evergreen.V46.LocalState.LogWithTime)
