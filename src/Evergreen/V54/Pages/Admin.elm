module Evergreen.V54.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V54.Id
import Evergreen.V54.LocalState
import Evergreen.V54.NonemptyDict
import Evergreen.V54.Pagination
import Evergreen.V54.Slack
import Evergreen.V54.Table
import Evergreen.V54.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V54.NonemptyDict.NonemptyDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V54.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V54.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V54.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
        }
    | ExpandSection Evergreen.V54.User.AdminUiSection
    | CollapseSection Evergreen.V54.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V54.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V54.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V54.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
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
    { table : Evergreen.V54.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V54.Pagination.Pagination Evergreen.V54.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V54.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V54.User.AdminUiSection
    | PressedExpandSection Evergreen.V54.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V54.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V54.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V54.Pagination.ToFrontend Evergreen.V54.LocalState.LogWithTime)
