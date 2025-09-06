module Evergreen.V49.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V49.Id
import Evergreen.V49.LocalState
import Evergreen.V49.NonemptyDict
import Evergreen.V49.Pagination
import Evergreen.V49.Slack
import Evergreen.V49.Table
import Evergreen.V49.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V49.NonemptyDict.NonemptyDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V49.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V49.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V49.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
        }
    | ExpandSection Evergreen.V49.User.AdminUiSection
    | CollapseSection Evergreen.V49.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V49.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V49.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V49.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
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
    { table : Evergreen.V49.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V49.Pagination.Pagination Evergreen.V49.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V49.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V49.User.AdminUiSection
    | PressedExpandSection Evergreen.V49.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V49.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V49.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V49.Pagination.ToFrontend Evergreen.V49.LocalState.LogWithTime)
