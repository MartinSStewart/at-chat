module Evergreen.V56.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V56.Id
import Evergreen.V56.LocalState
import Evergreen.V56.NonemptyDict
import Evergreen.V56.Pagination
import Evergreen.V56.Slack
import Evergreen.V56.Table
import Evergreen.V56.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V56.NonemptyDict.NonemptyDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V56.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V56.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V56.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
        }
    | ExpandSection Evergreen.V56.User.AdminUiSection
    | CollapseSection Evergreen.V56.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V56.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V56.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V56.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
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
    { table : Evergreen.V56.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V56.Pagination.Pagination Evergreen.V56.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V56.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V56.User.AdminUiSection
    | PressedExpandSection Evergreen.V56.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V56.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V56.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V56.Pagination.ToFrontend Evergreen.V56.LocalState.LogWithTime)
