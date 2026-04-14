module Evergreen.V197.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V197.Discord
import Evergreen.V197.Editable
import Evergreen.V197.Id
import Evergreen.V197.LocalState
import Evergreen.V197.NonemptyDict
import Evergreen.V197.Pagination
import Evergreen.V197.SessionIdHash
import Evergreen.V197.Slack
import Evergreen.V197.Table
import Evergreen.V197.ToBackendLog
import Evergreen.V197.User
import Evergreen.V197.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V197.NonemptyDict.NonemptyDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V197.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V197.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) Evergreen.V197.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V197.Pagination.Pagination Evergreen.V197.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V197.SessionIdHash.SessionIdHash (Evergreen.V197.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V197.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V197.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
        }
    | ExpandSection Evergreen.V197.User.AdminUiSection
    | CollapseSection Evergreen.V197.User.AdminUiSection
    | LogPageChanged (Evergreen.V197.Id.Id Evergreen.V197.Pagination.PageId) (Evergreen.V197.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V197.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V197.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V197.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    | DeleteGuild (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | CollapseGuild (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    | HideLog (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    | UnhideLog (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    | DisconnectClient Evergreen.V197.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
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
    { table : Evergreen.V197.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V197.Editable.Model
    , publicVapidKey : Evergreen.V197.Editable.Model
    , privateVapidKey : Evergreen.V197.Editable.Model
    , openRouterKey : Evergreen.V197.Editable.Model
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
    = PressedLogPage (Evergreen.V197.Id.Id Evergreen.V197.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V197.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V197.User.AdminUiSection
    | PressedExpandSection Evergreen.V197.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V197.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V197.Editable.Msg (Maybe Evergreen.V197.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V197.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V197.Editable.Msg Evergreen.V197.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V197.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V197.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
