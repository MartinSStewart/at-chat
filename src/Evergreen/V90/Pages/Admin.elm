module Evergreen.V90.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V90.Id
import Evergreen.V90.LocalState
import Evergreen.V90.NonemptyDict
import Evergreen.V90.Pagination
import Evergreen.V90.Slack
import Evergreen.V90.Table
import Evergreen.V90.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V90.NonemptyDict.NonemptyDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V90.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V90.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V90.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
        }
    | ExpandSection Evergreen.V90.User.AdminUiSection
    | CollapseSection Evergreen.V90.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V90.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V90.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V90.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
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
    { table : Evergreen.V90.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V90.Pagination.Pagination Evergreen.V90.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V90.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V90.User.AdminUiSection
    | PressedExpandSection Evergreen.V90.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V90.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V90.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V90.Pagination.ToFrontend Evergreen.V90.LocalState.LogWithTime)
