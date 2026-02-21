module Evergreen.V117.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V117.Id
import Evergreen.V117.LocalState
import Evergreen.V117.NonemptyDict
import Evergreen.V117.Pagination
import Evergreen.V117.Slack
import Evergreen.V117.Table
import Evergreen.V117.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V117.NonemptyDict.NonemptyDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V117.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V117.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
        }
    | ExpandSection Evergreen.V117.User.AdminUiSection
    | CollapseSection Evergreen.V117.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V117.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V117.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
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
    { table : Evergreen.V117.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V117.Pagination.Pagination Evergreen.V117.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V117.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V117.User.AdminUiSection
    | PressedExpandSection Evergreen.V117.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V117.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V117.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V117.Pagination.ToFrontend Evergreen.V117.LocalState.LogWithTime)
