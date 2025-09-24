module Evergreen.V101.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V101.Id
import Evergreen.V101.LocalState
import Evergreen.V101.NonemptyDict
import Evergreen.V101.Pagination
import Evergreen.V101.Slack
import Evergreen.V101.Table
import Evergreen.V101.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V101.NonemptyDict.NonemptyDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V101.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V101.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V101.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
        }
    | ExpandSection Evergreen.V101.User.AdminUiSection
    | CollapseSection Evergreen.V101.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V101.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V101.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V101.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
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
    { table : Evergreen.V101.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V101.Pagination.Pagination Evergreen.V101.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V101.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V101.User.AdminUiSection
    | PressedExpandSection Evergreen.V101.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V101.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V101.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V101.Pagination.ToFrontend Evergreen.V101.LocalState.LogWithTime)
