module Evergreen.V157.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V157.Discord
import Evergreen.V157.Editable
import Evergreen.V157.Id
import Evergreen.V157.LocalState
import Evergreen.V157.NonemptyDict
import Evergreen.V157.Pagination
import Evergreen.V157.SessionIdHash
import Evergreen.V157.Slack
import Evergreen.V157.Table
import Evergreen.V157.User
import Evergreen.V157.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V157.NonemptyDict.NonemptyDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V157.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V157.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) Evergreen.V157.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V157.Pagination.Pagination Evergreen.V157.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V157.SessionIdHash.SessionIdHash (Evergreen.V157.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V157.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
        }
    | ExpandSection Evergreen.V157.User.AdminUiSection
    | CollapseSection Evergreen.V157.User.AdminUiSection
    | LogPageChanged (Evergreen.V157.Id.Id Evergreen.V157.Pagination.PageId) (Evergreen.V157.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V157.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V157.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V157.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    | DeleteGuild (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | CollapseGuild (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    | HideLog (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    | UnhideLog (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    | DisconnectClient Evergreen.V157.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
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
    { table : Evergreen.V157.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V157.Editable.Model
    , publicVapidKey : Evergreen.V157.Editable.Model
    , privateVapidKey : Evergreen.V157.Editable.Model
    , openRouterKey : Evergreen.V157.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V157.Id.Id Evergreen.V157.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V157.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V157.User.AdminUiSection
    | PressedExpandSection Evergreen.V157.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V157.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V157.Editable.Msg (Maybe Evergreen.V157.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V157.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V157.Editable.Msg Evergreen.V157.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V157.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V157.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
