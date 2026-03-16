module Evergreen.V156.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V156.Discord
import Evergreen.V156.Editable
import Evergreen.V156.Id
import Evergreen.V156.LocalState
import Evergreen.V156.NonemptyDict
import Evergreen.V156.Pagination
import Evergreen.V156.SessionIdHash
import Evergreen.V156.Slack
import Evergreen.V156.Table
import Evergreen.V156.User
import Evergreen.V156.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V156.NonemptyDict.NonemptyDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V156.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V156.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V156.Pagination.Pagination Evergreen.V156.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V156.SessionIdHash.SessionIdHash (Evergreen.V156.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V156.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
        }
    | ExpandSection Evergreen.V156.User.AdminUiSection
    | CollapseSection Evergreen.V156.User.AdminUiSection
    | LogPageChanged (Evergreen.V156.Id.Id Evergreen.V156.Pagination.PageId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V156.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V156.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V156.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    | DeleteGuild (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | CollapseGuild (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    | HideLog (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    | UnhideLog (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    | DisconnectClient Evergreen.V156.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
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
    { table : Evergreen.V156.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V156.Editable.Model
    , publicVapidKey : Evergreen.V156.Editable.Model
    , privateVapidKey : Evergreen.V156.Editable.Model
    , openRouterKey : Evergreen.V156.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V156.Id.Id Evergreen.V156.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V156.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V156.User.AdminUiSection
    | PressedExpandSection Evergreen.V156.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V156.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V156.Editable.Msg (Maybe Evergreen.V156.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V156.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V156.Editable.Msg Evergreen.V156.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V156.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V156.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
