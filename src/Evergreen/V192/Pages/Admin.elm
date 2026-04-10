module Evergreen.V192.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V192.Discord
import Evergreen.V192.Editable
import Evergreen.V192.Id
import Evergreen.V192.LocalState
import Evergreen.V192.NonemptyDict
import Evergreen.V192.Pagination
import Evergreen.V192.SessionIdHash
import Evergreen.V192.Slack
import Evergreen.V192.Table
import Evergreen.V192.ToBackendLog
import Evergreen.V192.User
import Evergreen.V192.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V192.NonemptyDict.NonemptyDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V192.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V192.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) Evergreen.V192.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V192.Pagination.Pagination Evergreen.V192.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V192.SessionIdHash.SessionIdHash (Evergreen.V192.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V192.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V192.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
        }
    | ExpandSection Evergreen.V192.User.AdminUiSection
    | CollapseSection Evergreen.V192.User.AdminUiSection
    | LogPageChanged (Evergreen.V192.Id.Id Evergreen.V192.Pagination.PageId) (Evergreen.V192.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V192.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V192.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V192.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    | DeleteGuild (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | CollapseGuild (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    | HideLog (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    | UnhideLog (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    | DisconnectClient Evergreen.V192.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
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
    { table : Evergreen.V192.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V192.Editable.Model
    , publicVapidKey : Evergreen.V192.Editable.Model
    , privateVapidKey : Evergreen.V192.Editable.Model
    , openRouterKey : Evergreen.V192.Editable.Model
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
    = PressedLogPage (Evergreen.V192.Id.Id Evergreen.V192.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V192.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V192.User.AdminUiSection
    | PressedExpandSection Evergreen.V192.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V192.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V192.Editable.Msg (Maybe Evergreen.V192.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V192.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V192.Editable.Msg Evergreen.V192.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V192.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V192.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
