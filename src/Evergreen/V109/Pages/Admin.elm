module Evergreen.V109.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V109.Id
import Evergreen.V109.LocalState
import Evergreen.V109.NonemptyDict
import Evergreen.V109.Pagination
import Evergreen.V109.Slack
import Evergreen.V109.Table
import Evergreen.V109.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V109.NonemptyDict.NonemptyDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V109.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V109.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V109.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
        }
    | ExpandSection Evergreen.V109.User.AdminUiSection
    | CollapseSection Evergreen.V109.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V109.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V109.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V109.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
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
    { table : Evergreen.V109.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V109.Pagination.Pagination Evergreen.V109.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V109.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V109.User.AdminUiSection
    | PressedExpandSection Evergreen.V109.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V109.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V109.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V109.Pagination.ToFrontend Evergreen.V109.LocalState.LogWithTime)
