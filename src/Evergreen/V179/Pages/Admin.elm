module Evergreen.V179.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V179.Discord
import Evergreen.V179.Editable
import Evergreen.V179.Id
import Evergreen.V179.LocalState
import Evergreen.V179.NonemptyDict
import Evergreen.V179.Pagination
import Evergreen.V179.SessionIdHash
import Evergreen.V179.Slack
import Evergreen.V179.Table
import Evergreen.V179.User
import Evergreen.V179.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V179.NonemptyDict.NonemptyDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V179.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V179.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V179.Pagination.Pagination Evergreen.V179.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V179.SessionIdHash.SessionIdHash (Evergreen.V179.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V179.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
        }
    | ExpandSection Evergreen.V179.User.AdminUiSection
    | CollapseSection Evergreen.V179.User.AdminUiSection
    | LogPageChanged (Evergreen.V179.Id.Id Evergreen.V179.Pagination.PageId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V179.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V179.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V179.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    | DeleteGuild (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | CollapseGuild (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    | HideLog (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    | UnhideLog (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    | DisconnectClient Evergreen.V179.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
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
    { table : Evergreen.V179.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type ExportProgress
    = ExportStarting
    | ExportingGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingFinalStep


type alias Model =
    { highlightLog : Maybe (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V179.Editable.Model
    , publicVapidKey : Evergreen.V179.Editable.Model
    , privateVapidKey : Evergreen.V179.Editable.Model
    , openRouterKey : Evergreen.V179.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress


type Msg
    = PressedLogPage (Evergreen.V179.Id.Id Evergreen.V179.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V179.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V179.User.AdminUiSection
    | PressedExpandSection Evergreen.V179.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V179.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V179.Editable.Msg (Maybe Evergreen.V179.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V179.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V179.Editable.Msg Evergreen.V179.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V179.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V179.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
