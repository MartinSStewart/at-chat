module Evergreen.V76.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V76.Id
import Evergreen.V76.LocalState
import Evergreen.V76.NonemptyDict
import Evergreen.V76.Pagination
import Evergreen.V76.Slack
import Evergreen.V76.Table
import Evergreen.V76.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V76.NonemptyDict.NonemptyDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V76.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V76.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V76.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
        }
    | ExpandSection Evergreen.V76.User.AdminUiSection
    | CollapseSection Evergreen.V76.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V76.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V76.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V76.Slack.ClientSecret)


type UserTableId
    = ExistingUserId (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
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
    { table : Evergreen.V76.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V76.Pagination.Pagination Evergreen.V76.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V76.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V76.User.AdminUiSection
    | PressedExpandSection Evergreen.V76.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V76.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V76.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V76.Pagination.ToFrontend Evergreen.V76.LocalState.LogWithTime)
