module Evergreen.V104.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V104.Id
import Evergreen.V104.LocalState
import Evergreen.V104.NonemptyDict
import Evergreen.V104.Pagination
import Evergreen.V104.Slack
import Evergreen.V104.Table
import Evergreen.V104.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V104.NonemptyDict.NonemptyDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V104.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V104.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V104.Slack.ClientSecret
    , openRouterKey : Maybe String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
        }
    | ExpandSection Evergreen.V104.User.AdminUiSection
    | CollapseSection Evergreen.V104.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V104.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V104.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V104.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
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
    { table : Evergreen.V104.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V104.Pagination.Pagination Evergreen.V104.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V104.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V104.User.AdminUiSection
    | PressedExpandSection Evergreen.V104.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V104.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V104.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V104.Pagination.ToFrontend Evergreen.V104.LocalState.LogWithTime)
