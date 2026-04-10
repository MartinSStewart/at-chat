module Evergreen.V193.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V193.Discord
import Evergreen.V193.Editable
import Evergreen.V193.Id
import Evergreen.V193.LocalState
import Evergreen.V193.NonemptyDict
import Evergreen.V193.Pagination
import Evergreen.V193.SessionIdHash
import Evergreen.V193.Slack
import Evergreen.V193.Table
import Evergreen.V193.ToBackendLog
import Evergreen.V193.User
import Evergreen.V193.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V193.NonemptyDict.NonemptyDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V193.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V193.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V193.Pagination.Pagination Evergreen.V193.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V193.SessionIdHash.SessionIdHash (Evergreen.V193.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V193.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V193.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
        }
    | ExpandSection Evergreen.V193.User.AdminUiSection
    | CollapseSection Evergreen.V193.User.AdminUiSection
    | LogPageChanged (Evergreen.V193.Id.Id Evergreen.V193.Pagination.PageId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V193.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V193.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V193.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    | DeleteGuild (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | CollapseGuild (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    | HideLog (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    | UnhideLog (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    | DisconnectClient Evergreen.V193.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
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
    { table : Evergreen.V193.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V193.Editable.Model
    , publicVapidKey : Evergreen.V193.Editable.Model
    , privateVapidKey : Evergreen.V193.Editable.Model
    , openRouterKey : Evergreen.V193.Editable.Model
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
    = PressedLogPage (Evergreen.V193.Id.Id Evergreen.V193.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V193.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V193.User.AdminUiSection
    | PressedExpandSection Evergreen.V193.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V193.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V193.Editable.Msg (Maybe Evergreen.V193.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V193.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V193.Editable.Msg Evergreen.V193.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V193.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V193.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
