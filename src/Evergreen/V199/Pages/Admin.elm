module Evergreen.V199.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V199.Discord
import Evergreen.V199.Editable
import Evergreen.V199.Id
import Evergreen.V199.LocalState
import Evergreen.V199.NonemptyDict
import Evergreen.V199.Pagination
import Evergreen.V199.SessionIdHash
import Evergreen.V199.Slack
import Evergreen.V199.Table
import Evergreen.V199.ToBackendLog
import Evergreen.V199.User
import Evergreen.V199.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V199.NonemptyDict.NonemptyDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V199.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V199.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V199.Pagination.Pagination Evergreen.V199.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V199.SessionIdHash.SessionIdHash (Evergreen.V199.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V199.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V199.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
        }
    | ExpandSection Evergreen.V199.User.AdminUiSection
    | CollapseSection Evergreen.V199.User.AdminUiSection
    | LogPageChanged (Evergreen.V199.Id.Id Evergreen.V199.Pagination.PageId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V199.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V199.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V199.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | DeleteGuild (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | CollapseGuild (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | HideLog (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    | UnhideLog (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    | DisconnectClient Evergreen.V199.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
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
    { table : Evergreen.V199.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V199.Editable.Model
    , publicVapidKey : Evergreen.V199.Editable.Model
    , privateVapidKey : Evergreen.V199.Editable.Model
    , openRouterKey : Evergreen.V199.Editable.Model
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
    = PressedLogPage (Evergreen.V199.Id.Id Evergreen.V199.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V199.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V199.User.AdminUiSection
    | PressedExpandSection Evergreen.V199.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V199.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V199.Editable.Msg (Maybe Evergreen.V199.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V199.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V199.Editable.Msg Evergreen.V199.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V199.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V199.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
