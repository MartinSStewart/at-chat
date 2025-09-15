module Evergreen.V61.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V61.Id
import Evergreen.V61.LocalState
import Evergreen.V61.NonemptyDict
import Evergreen.V61.Pagination
import Evergreen.V61.Slack
import Evergreen.V61.Table
import Evergreen.V61.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V61.NonemptyDict.NonemptyDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V61.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V61.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V61.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
        }
    | ExpandSection Evergreen.V61.User.AdminUiSection
    | CollapseSection Evergreen.V61.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V61.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V61.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V61.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
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
    { table : Evergreen.V61.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V61.Pagination.Pagination Evergreen.V61.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V61.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V61.User.AdminUiSection
    | PressedExpandSection Evergreen.V61.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V61.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V61.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V61.Pagination.ToFrontend Evergreen.V61.LocalState.LogWithTime)
