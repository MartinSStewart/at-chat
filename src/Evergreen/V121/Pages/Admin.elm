module Evergreen.V121.Pages.Admin exposing (..)

import Array
import Effect.Time
import Evergreen.V121.Discord.Id
import Evergreen.V121.GuildName
import Evergreen.V121.Id
import Evergreen.V121.LocalState
import Evergreen.V121.NonemptyDict
import Evergreen.V121.NonemptySet
import Evergreen.V121.Pagination
import Evergreen.V121.Slack
import Evergreen.V121.Table
import Evergreen.V121.User
import SeqDict
import SeqSet


type alias InitAdminData =
    { lastLogPageViewed : Int
    , users : Evergreen.V121.NonemptyDict.NonemptyDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Evergreen.V121.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V121.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V121.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId)
            { members : Evergreen.V121.NonemptySet.NonemptySet (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) Evergreen.V121.LocalState.DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId)
            { name : Evergreen.V121.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
            }
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
        }
    | ExpandSection Evergreen.V121.User.AdminUiSection
    | CollapseSection Evergreen.V121.User.AdminUiSection
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey Evergreen.V121.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V121.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId)


type UserTableId
    = ExistingUserId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
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
    { table : Evergreen.V121.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Evergreen.V121.Pagination.Pagination Evergreen.V121.LocalState.LogWithTime
    }


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
    | PressedCollapseSection Evergreen.V121.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V121.User.AdminUiSection
    | PressedExpandSection Evergreen.V121.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V121.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId)


type ToBackend
    = LogPaginationToBackend Evergreen.V121.Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Evergreen.V121.Pagination.ToFrontend Evergreen.V121.LocalState.LogWithTime)
