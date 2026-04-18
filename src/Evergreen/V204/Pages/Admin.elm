module Evergreen.V204.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V204.Discord
import Evergreen.V204.Editable
import Evergreen.V204.Id
import Evergreen.V204.LocalState
import Evergreen.V204.NonemptyDict
import Evergreen.V204.Pagination
import Evergreen.V204.SessionIdHash
import Evergreen.V204.Slack
import Evergreen.V204.Table
import Evergreen.V204.ToBackendLog
import Evergreen.V204.User
import Evergreen.V204.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V204.NonemptyDict.NonemptyDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V204.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V204.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V204.Pagination.Pagination Evergreen.V204.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V204.SessionIdHash.SessionIdHash (Evergreen.V204.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V204.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V204.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
        }
    | ExpandSection Evergreen.V204.User.AdminUiSection
    | CollapseSection Evergreen.V204.User.AdminUiSection
    | LogPageChanged (Evergreen.V204.Id.Id Evergreen.V204.Pagination.PageId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V204.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V204.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V204.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | DeleteGuild (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | CollapseGuild (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | HideLog (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    | UnhideLog (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    | DisconnectClient Evergreen.V204.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
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
    { table : Evergreen.V204.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V204.Editable.Model
    , publicVapidKey : Evergreen.V204.Editable.Model
    , privateVapidKey : Evergreen.V204.Editable.Model
    , openRouterKey : Evergreen.V204.Editable.Model
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
    = PressedLogPage (Evergreen.V204.Id.Id Evergreen.V204.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V204.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V204.User.AdminUiSection
    | PressedExpandSection Evergreen.V204.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V204.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V204.Editable.Msg (Maybe Evergreen.V204.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V204.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V204.Editable.Msg Evergreen.V204.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V204.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V204.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
