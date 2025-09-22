module Evergreen.V93.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V93.Id
import Evergreen.V93.LocalState
import Evergreen.V93.NonemptyDict
import Evergreen.V93.Pagination
import Evergreen.V93.Slack
import Evergreen.V93.Table
import Evergreen.V93.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V93.NonemptyDict.NonemptyDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V93.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V93.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V93.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
        }
    | ExpandSection Evergreen.V93.User.AdminUiSection
    | CollapseSection Evergreen.V93.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V93.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V93.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V93.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
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
    { table : Evergreen.V93.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V93.Pagination.Pagination Evergreen.V93.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V93.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V93.User.AdminUiSection
    | PressedExpandSection Evergreen.V93.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V93.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V93.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V93.Pagination.ToFrontend Evergreen.V93.LocalState.LogWithTime)
