module Evergreen.V102.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V102.Id
import Evergreen.V102.LocalState
import Evergreen.V102.NonemptyDict
import Evergreen.V102.Pagination
import Evergreen.V102.Slack
import Evergreen.V102.Table
import Evergreen.V102.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V102.NonemptyDict.NonemptyDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V102.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V102.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V102.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
        }
    | ExpandSection Evergreen.V102.User.AdminUiSection
    | CollapseSection Evergreen.V102.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V102.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V102.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V102.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
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
    { table : Evergreen.V102.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V102.Pagination.Pagination Evergreen.V102.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V102.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V102.User.AdminUiSection
    | PressedExpandSection Evergreen.V102.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V102.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V102.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V102.Pagination.ToFrontend Evergreen.V102.LocalState.LogWithTime)
