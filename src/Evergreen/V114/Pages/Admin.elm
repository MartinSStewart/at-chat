module Evergreen.V114.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V114.Id
import Evergreen.V114.LocalState
import Evergreen.V114.NonemptyDict
import Evergreen.V114.Pagination
import Evergreen.V114.Slack
import Evergreen.V114.Table
import Evergreen.V114.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V114.NonemptyDict.NonemptyDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V114.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V114.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
        }
    | ExpandSection Evergreen.V114.User.AdminUiSection
    | CollapseSection Evergreen.V114.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V114.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V114.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
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
    { table : Evergreen.V114.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V114.Pagination.Pagination Evergreen.V114.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V114.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V114.User.AdminUiSection
    | PressedExpandSection Evergreen.V114.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V114.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V114.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V114.Pagination.ToFrontend Evergreen.V114.LocalState.LogWithTime)
