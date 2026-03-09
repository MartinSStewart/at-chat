module Evergreen.V147.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Time
import Evergreen.V147.Discord
import Evergreen.V147.Editable
import Evergreen.V147.Id
import Evergreen.V147.LocalState
import Evergreen.V147.NonemptyDict
import Evergreen.V147.Pagination
import Evergreen.V147.Slack
import Evergreen.V147.Table
import Evergreen.V147.User
import Evergreen.V147.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V147.NonemptyDict.NonemptyDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V147.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V147.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) Evergreen.V147.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) Evergreen.V147.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V147.Pagination.Pagination Evergreen.V147.LocalState.LogWithTime
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
        }
    | ExpandSection Evergreen.V147.User.AdminUiSection
    | CollapseSection Evergreen.V147.User.AdminUiSection
    | LogPageChanged (Evergreen.V147.Id.Id Evergreen.V147.Pagination.PageId) (Evergreen.V147.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V147.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V147.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V147.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    | DeleteGuild (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | CollapseGuild (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    | HideLog (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    | UnhideLog (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)


type UserTableId
    = ExistingUserId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
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
    { table : Evergreen.V147.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V147.Editable.Model
    , publicVapidKey : Evergreen.V147.Editable.Model
    , privateVapidKey : Evergreen.V147.Editable.Model
    , openRouterKey : Evergreen.V147.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V147.Id.Id Evergreen.V147.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V147.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V147.User.AdminUiSection
    | PressedExpandSection Evergreen.V147.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V147.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V147.Editable.Msg (Maybe Evergreen.V147.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V147.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V147.Editable.Msg Evergreen.V147.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V147.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
    | PressedShowHiddenLogs Bool


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
