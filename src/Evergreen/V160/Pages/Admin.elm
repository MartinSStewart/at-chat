module Evergreen.V160.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V160.Discord
import Evergreen.V160.Editable
import Evergreen.V160.Id
import Evergreen.V160.LocalState
import Evergreen.V160.NonemptyDict
import Evergreen.V160.Pagination
import Evergreen.V160.SessionIdHash
import Evergreen.V160.Slack
import Evergreen.V160.Table
import Evergreen.V160.User
import Evergreen.V160.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V160.NonemptyDict.NonemptyDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V160.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V160.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) Evergreen.V160.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V160.Pagination.Pagination Evergreen.V160.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V160.SessionIdHash.SessionIdHash (Evergreen.V160.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V160.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
        }
    | ExpandSection Evergreen.V160.User.AdminUiSection
    | CollapseSection Evergreen.V160.User.AdminUiSection
    | LogPageChanged (Evergreen.V160.Id.Id Evergreen.V160.Pagination.PageId) (Evergreen.V160.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V160.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V160.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V160.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    | DeleteGuild (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | CollapseGuild (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    | HideLog (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    | UnhideLog (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    | DisconnectClient Evergreen.V160.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
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
    { table : Evergreen.V160.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V160.Editable.Model
    , publicVapidKey : Evergreen.V160.Editable.Model
    , privateVapidKey : Evergreen.V160.Editable.Model
    , openRouterKey : Evergreen.V160.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V160.Id.Id Evergreen.V160.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V160.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V160.User.AdminUiSection
    | PressedExpandSection Evergreen.V160.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V160.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V160.Editable.Msg (Maybe Evergreen.V160.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V160.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V160.Editable.Msg Evergreen.V160.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V160.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V160.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
