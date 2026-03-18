module Evergreen.V158.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V158.Discord
import Evergreen.V158.Editable
import Evergreen.V158.Id
import Evergreen.V158.LocalState
import Evergreen.V158.NonemptyDict
import Evergreen.V158.Pagination
import Evergreen.V158.SessionIdHash
import Evergreen.V158.Slack
import Evergreen.V158.Table
import Evergreen.V158.User
import Evergreen.V158.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V158.NonemptyDict.NonemptyDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V158.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V158.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) Evergreen.V158.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V158.Pagination.Pagination Evergreen.V158.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V158.SessionIdHash.SessionIdHash (Evergreen.V158.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V158.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
        }
    | ExpandSection Evergreen.V158.User.AdminUiSection
    | CollapseSection Evergreen.V158.User.AdminUiSection
    | LogPageChanged (Evergreen.V158.Id.Id Evergreen.V158.Pagination.PageId) (Evergreen.V158.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V158.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V158.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V158.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    | DeleteGuild (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | CollapseGuild (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    | HideLog (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    | UnhideLog (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    | DisconnectClient Evergreen.V158.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
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
    { table : Evergreen.V158.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type alias Model =
    { highlightLog : Maybe (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V158.Editable.Model
    , publicVapidKey : Evergreen.V158.Editable.Model
    , privateVapidKey : Evergreen.V158.Editable.Model
    , openRouterKey : Evergreen.V158.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type Msg
    = PressedLogPage (Evergreen.V158.Id.Id Evergreen.V158.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V158.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V158.User.AdminUiSection
    | PressedExpandSection Evergreen.V158.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V158.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V158.Editable.Msg (Maybe Evergreen.V158.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V158.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V158.Editable.Msg Evergreen.V158.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V158.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V158.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse Bytes.Bytes
    | ExportSubsetBackendResponse Bytes.Bytes
    | ImportBackendResponse (Result () ())
