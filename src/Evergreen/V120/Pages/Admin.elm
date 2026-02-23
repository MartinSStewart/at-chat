module Evergreen.V120.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V120.Discord.Id
import Evergreen.V120.Id
import Evergreen.V120.LocalState
import Evergreen.V120.NonemptyDict
import Evergreen.V120.NonemptySet
import Evergreen.V120.Pagination
import Evergreen.V120.Slack
import Evergreen.V120.Table
import Evergreen.V120.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V120.NonemptyDict.NonemptyDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V120.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V120.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)
            { members : Evergreen.V120.NonemptySet.NonemptySet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.LocalState.DiscordUserData_ForAdmin
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
        }
    | ExpandSection Evergreen.V120.User.AdminUiSection
    | CollapseSection Evergreen.V120.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V120.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V120.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)


type UserTableId
    = ExistingUserId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
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
    { table : Evergreen.V120.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V120.Pagination.Pagination Evergreen.V120.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V120.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V120.User.AdminUiSection
    | PressedExpandSection Evergreen.V120.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V120.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)


type ToBackend
    = LogPaginationToBackend Evergreen.V120.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V120.Pagination.ToFrontend Evergreen.V120.LocalState.LogWithTime)
