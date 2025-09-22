module Evergreen.V94.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V94.Id
import Evergreen.V94.LocalState
import Evergreen.V94.NonemptyDict
import Evergreen.V94.Pagination
import Evergreen.V94.Slack
import Evergreen.V94.Table
import Evergreen.V94.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V94.NonemptyDict.NonemptyDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V94.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V94.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V94.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
        }
    | ExpandSection Evergreen.V94.User.AdminUiSection
    | CollapseSection Evergreen.V94.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V94.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V94.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V94.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
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
    { table : Evergreen.V94.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V94.Pagination.Pagination Evergreen.V94.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V94.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V94.User.AdminUiSection
    | PressedExpandSection Evergreen.V94.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V94.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V94.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V94.Pagination.ToFrontend Evergreen.V94.LocalState.LogWithTime)
