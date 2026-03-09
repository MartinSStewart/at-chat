module Evergreen.V148.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V148.Discord
import Evergreen.V148.Editable
import Evergreen.V148.Id
import Evergreen.V148.LocalState
import Evergreen.V148.NonemptyDict
import Evergreen.V148.Pagination
import Evergreen.V148.Slack
import Evergreen.V148.Table
import Evergreen.V148.User
import Evergreen.V148.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V148.NonemptyDict.NonemptyDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V148.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V148.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) Evergreen.V148.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) Evergreen.V148.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V148.Pagination.Pagination Evergreen.V148.LocalState.LogWithTime
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
        }
    | ExpandSection Evergreen.V148.User.AdminUiSection
    | CollapseSection Evergreen.V148.User.AdminUiSection
    | LogPageChanged (Evergreen.V148.Id.Id Evergreen.V148.Pagination.PageId) (Evergreen.V148.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V148.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V148.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V148.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    | DeleteGuild (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | CollapseGuild (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    | HideLog (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    | UnhideLog (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)


type UserTableId
    = ExistingUserId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
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
    { table : Evergreen.V148.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V148.Editable.Model
    , publicVapidKey : Evergreen.V148.Editable.Model
    , privateVapidKey : Evergreen.V148.Editable.Model
    , openRouterKey : Evergreen.V148.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V148.Id.Id Evergreen.V148.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V148.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V148.User.AdminUiSection
    | PressedExpandSection Evergreen.V148.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V148.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V148.Editable.Msg (Maybe Evergreen.V148.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V148.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V148.Editable.Msg Evergreen.V148.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V148.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
    | PressedShowHiddenLogs Bool


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
