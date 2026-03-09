module Evergreen.V149.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V149.Discord
import Evergreen.V149.Editable
import Evergreen.V149.Id
import Evergreen.V149.LocalState
import Evergreen.V149.NonemptyDict
import Evergreen.V149.Pagination
import Evergreen.V149.Slack
import Evergreen.V149.Table
import Evergreen.V149.User
import Evergreen.V149.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V149.NonemptyDict.NonemptyDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V149.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V149.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) Evergreen.V149.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) Evergreen.V149.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V149.Pagination.Pagination Evergreen.V149.LocalState.LogWithTime
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
        }
    | ExpandSection Evergreen.V149.User.AdminUiSection
    | CollapseSection Evergreen.V149.User.AdminUiSection
    | LogPageChanged (Evergreen.V149.Id.Id Evergreen.V149.Pagination.PageId) (Evergreen.V149.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V149.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V149.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V149.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    | DeleteGuild (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | CollapseGuild (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    | HideLog (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    | UnhideLog (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)


type UserTableId
    = ExistingUserId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
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
    { table : Evergreen.V149.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V149.Editable.Model
    , publicVapidKey : Evergreen.V149.Editable.Model
    , privateVapidKey : Evergreen.V149.Editable.Model
    , openRouterKey : Evergreen.V149.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V149.Id.Id Evergreen.V149.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V149.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V149.User.AdminUiSection
    | PressedExpandSection Evergreen.V149.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V149.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V149.Editable.Msg (Maybe Evergreen.V149.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V149.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V149.Editable.Msg Evergreen.V149.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V149.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
    | PressedShowHiddenLogs Bool


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
