module Evergreen.V97.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V97.Id
import Evergreen.V97.LocalState
import Evergreen.V97.NonemptyDict
import Evergreen.V97.Pagination
import Evergreen.V97.Slack
import Evergreen.V97.Table
import Evergreen.V97.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V97.NonemptyDict.NonemptyDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V97.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V97.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V97.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
        }
    | ExpandSection Evergreen.V97.User.AdminUiSection
    | CollapseSection Evergreen.V97.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V97.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V97.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V97.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
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
    { table : Evergreen.V97.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V97.Pagination.Pagination Evergreen.V97.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V97.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V97.User.AdminUiSection
    | PressedExpandSection Evergreen.V97.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V97.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V97.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V97.Pagination.ToFrontend Evergreen.V97.LocalState.LogWithTime)
