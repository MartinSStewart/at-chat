module Evergreen.V60.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V60.Id
import Evergreen.V60.LocalState
import Evergreen.V60.NonemptyDict
import Evergreen.V60.Pagination
import Evergreen.V60.Slack
import Evergreen.V60.Table
import Evergreen.V60.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V60.NonemptyDict.NonemptyDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V60.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V60.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V60.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
        }
    | ExpandSection Evergreen.V60.User.AdminUiSection
    | CollapseSection Evergreen.V60.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V60.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V60.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V60.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
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
    { table : Evergreen.V60.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V60.Pagination.Pagination Evergreen.V60.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V60.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V60.User.AdminUiSection
    | PressedExpandSection Evergreen.V60.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V60.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V60.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V60.Pagination.ToFrontend Evergreen.V60.LocalState.LogWithTime)
