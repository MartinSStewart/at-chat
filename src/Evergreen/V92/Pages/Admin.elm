module Evergreen.V92.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V92.Id
import Evergreen.V92.LocalState
import Evergreen.V92.NonemptyDict
import Evergreen.V92.Pagination
import Evergreen.V92.Slack
import Evergreen.V92.Table
import Evergreen.V92.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V92.NonemptyDict.NonemptyDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V92.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V92.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V92.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
        }
    | ExpandSection Evergreen.V92.User.AdminUiSection
    | CollapseSection Evergreen.V92.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V92.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V92.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V92.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
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
    { table : Evergreen.V92.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V92.Pagination.Pagination Evergreen.V92.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V92.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V92.User.AdminUiSection
    | PressedExpandSection Evergreen.V92.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V92.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V92.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V92.Pagination.ToFrontend Evergreen.V92.LocalState.LogWithTime)
