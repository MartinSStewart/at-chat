module Evergreen.V53.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V53.Id
import Evergreen.V53.LocalState
import Evergreen.V53.NonemptyDict
import Evergreen.V53.Pagination
import Evergreen.V53.Slack
import Evergreen.V53.Table
import Evergreen.V53.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V53.NonemptyDict.NonemptyDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V53.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V53.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V53.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
        }
    | ExpandSection Evergreen.V53.User.AdminUiSection
    | CollapseSection Evergreen.V53.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V53.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V53.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V53.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
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
    { table : Evergreen.V53.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V53.Pagination.Pagination Evergreen.V53.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V53.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V53.User.AdminUiSection
    | PressedExpandSection Evergreen.V53.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V53.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V53.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V53.Pagination.ToFrontend Evergreen.V53.LocalState.LogWithTime)
