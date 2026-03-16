module Evergreen.V154.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V154.Discord
import Evergreen.V154.Editable
import Evergreen.V154.Id
import Evergreen.V154.LocalState
import Evergreen.V154.NonemptyDict
import Evergreen.V154.Pagination
import Evergreen.V154.SessionIdHash
import Evergreen.V154.Slack
import Evergreen.V154.Table
import Evergreen.V154.User
import Evergreen.V154.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V154.NonemptyDict.NonemptyDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V154.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V154.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V154.Pagination.Pagination Evergreen.V154.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V154.SessionIdHash.SessionIdHash (Evergreen.V154.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V154.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
        }
    | ExpandSection Evergreen.V154.User.AdminUiSection
    | CollapseSection Evergreen.V154.User.AdminUiSection
    | LogPageChanged (Evergreen.V154.Id.Id Evergreen.V154.Pagination.PageId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V154.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V154.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V154.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    | DeleteGuild (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | CollapseGuild (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    | HideLog (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    | UnhideLog (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    | DisconnectClient Evergreen.V154.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
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
    { table : Evergreen.V154.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V154.Editable.Model
    , publicVapidKey : Evergreen.V154.Editable.Model
    , privateVapidKey : Evergreen.V154.Editable.Model
    , openRouterKey : Evergreen.V154.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V154.Id.Id Evergreen.V154.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V154.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V154.User.AdminUiSection
    | PressedExpandSection Evergreen.V154.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V154.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V154.Editable.Msg (Maybe Evergreen.V154.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V154.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V154.Editable.Msg Evergreen.V154.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V154.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V154.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
