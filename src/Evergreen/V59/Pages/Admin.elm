module Evergreen.V59.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V59.Id
import Evergreen.V59.LocalState
import Evergreen.V59.NonemptyDict
import Evergreen.V59.Pagination
import Evergreen.V59.Slack
import Evergreen.V59.Table
import Evergreen.V59.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V59.NonemptyDict.NonemptyDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V59.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V59.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V59.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
        }
    | ExpandSection Evergreen.V59.User.AdminUiSection
    | CollapseSection Evergreen.V59.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V59.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V59.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V59.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
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
    { table : Evergreen.V59.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V59.Pagination.Pagination Evergreen.V59.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V59.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V59.User.AdminUiSection
    | PressedExpandSection Evergreen.V59.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V59.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V59.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V59.Pagination.ToFrontend Evergreen.V59.LocalState.LogWithTime)
