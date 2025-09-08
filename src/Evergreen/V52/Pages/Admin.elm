module Evergreen.V52.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V52.Id
import Evergreen.V52.LocalState
import Evergreen.V52.NonemptyDict
import Evergreen.V52.Pagination
import Evergreen.V52.Slack
import Evergreen.V52.Table
import Evergreen.V52.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V52.NonemptyDict.NonemptyDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V52.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V52.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V52.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
        }
    | ExpandSection Evergreen.V52.User.AdminUiSection
    | CollapseSection Evergreen.V52.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V52.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V52.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V52.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
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
    { table : Evergreen.V52.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V52.Pagination.Pagination Evergreen.V52.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V52.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V52.User.AdminUiSection
    | PressedExpandSection Evergreen.V52.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V52.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V52.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V52.Pagination.ToFrontend Evergreen.V52.LocalState.LogWithTime)
