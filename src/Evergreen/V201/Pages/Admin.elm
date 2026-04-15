module Evergreen.V201.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V201.Discord
import Evergreen.V201.Editable
import Evergreen.V201.Id
import Evergreen.V201.LocalState
import Evergreen.V201.NonemptyDict
import Evergreen.V201.Pagination
import Evergreen.V201.SessionIdHash
import Evergreen.V201.Slack
import Evergreen.V201.Table
import Evergreen.V201.ToBackendLog
import Evergreen.V201.User
import Evergreen.V201.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V201.NonemptyDict.NonemptyDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V201.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V201.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V201.Pagination.Pagination Evergreen.V201.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V201.SessionIdHash.SessionIdHash (Evergreen.V201.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V201.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V201.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
        }
    | ExpandSection Evergreen.V201.User.AdminUiSection
    | CollapseSection Evergreen.V201.User.AdminUiSection
    | LogPageChanged (Evergreen.V201.Id.Id Evergreen.V201.Pagination.PageId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V201.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V201.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V201.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | DeleteGuild (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | CollapseGuild (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | HideLog (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    | UnhideLog (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    | DisconnectClient Evergreen.V201.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
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
    { table : Evergreen.V201.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V201.Editable.Model
    , publicVapidKey : Evergreen.V201.Editable.Model
    , privateVapidKey : Evergreen.V201.Editable.Model
    , openRouterKey : Evergreen.V201.Editable.Model
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
    = PressedLogPage (Evergreen.V201.Id.Id Evergreen.V201.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V201.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V201.User.AdminUiSection
    | PressedExpandSection Evergreen.V201.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V201.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V201.Editable.Msg (Maybe Evergreen.V201.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V201.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V201.Editable.Msg Evergreen.V201.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V201.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V201.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
