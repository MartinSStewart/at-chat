module Evergreen.V116.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V116.Id
import Evergreen.V116.LocalState
import Evergreen.V116.NonemptyDict
import Evergreen.V116.Pagination
import Evergreen.V116.Slack
import Evergreen.V116.Table
import Evergreen.V116.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V116.NonemptyDict.NonemptyDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V116.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V116.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
        }
    | ExpandSection Evergreen.V116.User.AdminUiSection
    | CollapseSection Evergreen.V116.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V116.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V116.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
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
    { table : Evergreen.V116.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V116.Pagination.Pagination Evergreen.V116.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V116.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V116.User.AdminUiSection
    | PressedExpandSection Evergreen.V116.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V116.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V116.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V116.Pagination.ToFrontend Evergreen.V116.LocalState.LogWithTime)
