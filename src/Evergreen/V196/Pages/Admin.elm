module Evergreen.V196.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V196.Discord
import Evergreen.V196.Editable
import Evergreen.V196.Id
import Evergreen.V196.LocalState
import Evergreen.V196.NonemptyDict
import Evergreen.V196.Pagination
import Evergreen.V196.SessionIdHash
import Evergreen.V196.Slack
import Evergreen.V196.Table
import Evergreen.V196.ToBackendLog
import Evergreen.V196.User
import Evergreen.V196.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V196.NonemptyDict.NonemptyDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V196.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V196.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) Evergreen.V196.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) Evergreen.V196.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) Evergreen.V196.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) Evergreen.V196.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V196.Pagination.Pagination Evergreen.V196.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V196.SessionIdHash.SessionIdHash (Evergreen.V196.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V196.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V196.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
        }
    | ExpandSection Evergreen.V196.User.AdminUiSection
    | CollapseSection Evergreen.V196.User.AdminUiSection
    | LogPageChanged (Evergreen.V196.Id.Id Evergreen.V196.Pagination.PageId) (Evergreen.V196.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V196.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V196.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V196.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    | DeleteGuild (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    | CollapseGuild (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    | HideLog (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    | UnhideLog (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    | DisconnectClient Evergreen.V196.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
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
    { table : Evergreen.V196.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
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
    | ExportingFinalStep Bytes.Bytes


type alias Model =
    { highlightLog : Maybe (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V196.Editable.Model
    , publicVapidKey : Evergreen.V196.Editable.Model
    , privateVapidKey : Evergreen.V196.Editable.Model
    , openRouterKey : Evergreen.V196.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V196.Id.Id Evergreen.V196.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V196.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V196.User.AdminUiSection
    | PressedExpandSection Evergreen.V196.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V196.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V196.Editable.Msg (Maybe Evergreen.V196.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V196.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V196.Editable.Msg Evergreen.V196.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V196.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V196.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
