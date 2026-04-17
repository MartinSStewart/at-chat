module Evergreen.V203.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V203.Discord
import Evergreen.V203.Editable
import Evergreen.V203.Id
import Evergreen.V203.LocalState
import Evergreen.V203.NonemptyDict
import Evergreen.V203.Pagination
import Evergreen.V203.SessionIdHash
import Evergreen.V203.Slack
import Evergreen.V203.Table
import Evergreen.V203.ToBackendLog
import Evergreen.V203.User
import Evergreen.V203.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V203.NonemptyDict.NonemptyDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V203.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V203.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V203.Pagination.Pagination Evergreen.V203.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V203.SessionIdHash.SessionIdHash (Evergreen.V203.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V203.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V203.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
        }
    | ExpandSection Evergreen.V203.User.AdminUiSection
    | CollapseSection Evergreen.V203.User.AdminUiSection
    | LogPageChanged (Evergreen.V203.Id.Id Evergreen.V203.Pagination.PageId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V203.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V203.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V203.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | DeleteGuild (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | CollapseGuild (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | HideLog (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    | UnhideLog (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    | DisconnectClient Evergreen.V203.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
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
    { table : Evergreen.V203.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V203.Editable.Model
    , publicVapidKey : Evergreen.V203.Editable.Model
    , privateVapidKey : Evergreen.V203.Editable.Model
    , openRouterKey : Evergreen.V203.Editable.Model
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
    = PressedLogPage (Evergreen.V203.Id.Id Evergreen.V203.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V203.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V203.User.AdminUiSection
    | PressedExpandSection Evergreen.V203.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V203.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V203.Editable.Msg (Maybe Evergreen.V203.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V203.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V203.Editable.Msg Evergreen.V203.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V203.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V203.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
