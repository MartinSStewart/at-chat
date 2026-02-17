module Evergreen.V115.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V115.Id
import Evergreen.V115.LocalState
import Evergreen.V115.NonemptyDict
import Evergreen.V115.Pagination
import Evergreen.V115.Slack
import Evergreen.V115.Table
import Evergreen.V115.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V115.NonemptyDict.NonemptyDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V115.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V115.Slack.ClientSecret
    , openRouterKey : Maybe String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
        }
    | ExpandSection Evergreen.V115.User.AdminUiSection
    | CollapseSection Evergreen.V115.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V115.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V115.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
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
    { table : Evergreen.V115.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V115.Pagination.Pagination Evergreen.V115.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V115.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V115.User.AdminUiSection
    | PressedExpandSection Evergreen.V115.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V115.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V115.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V115.Pagination.ToFrontend Evergreen.V115.LocalState.LogWithTime)
