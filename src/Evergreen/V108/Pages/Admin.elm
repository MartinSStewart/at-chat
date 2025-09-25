module Evergreen.V108.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V108.Id
import Evergreen.V108.LocalState
import Evergreen.V108.NonemptyDict
import Evergreen.V108.Pagination
import Evergreen.V108.Slack
import Evergreen.V108.Table
import Evergreen.V108.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V108.NonemptyDict.NonemptyDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Effect.Time.Posix
    , botToken : Maybe Evergreen.V108.LocalState.DiscordBotToken
    , privateVapidKey : Evergreen.V108.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V108.Slack.ClientSecret
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
        }
    | ExpandSection Evergreen.V108.User.AdminUiSection
    | CollapseSection Evergreen.V108.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetDiscordBotToken (Maybe Evergreen.V108.LocalState.DiscordBotToken)
    | SetPrivateVapidKey Evergreen.V108.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V108.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


type UserTableId
    = ExistingUserId (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
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
    { table : Evergreen.V108.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V108.Pagination.Pagination Evergreen.V108.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V108.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V108.User.AdminUiSection
    | PressedExpandSection Evergreen.V108.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V108.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Evergreen.V108.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V108.Pagination.ToFrontend Evergreen.V108.LocalState.LogWithTime)
