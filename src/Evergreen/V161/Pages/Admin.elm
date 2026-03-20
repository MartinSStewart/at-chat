module Evergreen.V161.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V161.Discord
import Evergreen.V161.Editable
import Evergreen.V161.Id
import Evergreen.V161.LocalState
import Evergreen.V161.NonemptyDict
import Evergreen.V161.Pagination
import Evergreen.V161.SessionIdHash
import Evergreen.V161.Slack
import Evergreen.V161.Table
import Evergreen.V161.User
import Evergreen.V161.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V161.NonemptyDict.NonemptyDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V161.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V161.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) Evergreen.V161.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V161.Pagination.Pagination Evergreen.V161.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V161.SessionIdHash.SessionIdHash (Evergreen.V161.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V161.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
        }
    | ExpandSection Evergreen.V161.User.AdminUiSection
    | CollapseSection Evergreen.V161.User.AdminUiSection
    | LogPageChanged (Evergreen.V161.Id.Id Evergreen.V161.Pagination.PageId) (Evergreen.V161.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V161.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V161.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V161.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    | DeleteGuild (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | CollapseGuild (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    | HideLog (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    | UnhideLog (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    | DisconnectClient Evergreen.V161.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
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
    { table : Evergreen.V161.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V161.Editable.Model
    , publicVapidKey : Evergreen.V161.Editable.Model
    , privateVapidKey : Evergreen.V161.Editable.Model
    , openRouterKey : Evergreen.V161.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V161.Id.Id Evergreen.V161.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V161.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V161.User.AdminUiSection
    | PressedExpandSection Evergreen.V161.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V161.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V161.Editable.Msg (Maybe Evergreen.V161.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V161.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V161.Editable.Msg Evergreen.V161.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V161.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V161.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
