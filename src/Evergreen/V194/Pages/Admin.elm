module Evergreen.V194.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V194.Discord
import Evergreen.V194.Editable
import Evergreen.V194.Id
import Evergreen.V194.LocalState
import Evergreen.V194.NonemptyDict
import Evergreen.V194.Pagination
import Evergreen.V194.SessionIdHash
import Evergreen.V194.Slack
import Evergreen.V194.Table
import Evergreen.V194.ToBackendLog
import Evergreen.V194.User
import Evergreen.V194.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V194.NonemptyDict.NonemptyDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V194.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V194.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V194.Pagination.Pagination Evergreen.V194.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V194.SessionIdHash.SessionIdHash (Evergreen.V194.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V194.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V194.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
        }
    | ExpandSection Evergreen.V194.User.AdminUiSection
    | CollapseSection Evergreen.V194.User.AdminUiSection
    | LogPageChanged (Evergreen.V194.Id.Id Evergreen.V194.Pagination.PageId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V194.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V194.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V194.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    | DeleteGuild (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | CollapseGuild (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    | HideLog (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    | UnhideLog (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    | DisconnectClient Evergreen.V194.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
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
    { table : Evergreen.V194.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V194.Editable.Model
    , publicVapidKey : Evergreen.V194.Editable.Model
    , privateVapidKey : Evergreen.V194.Editable.Model
    , openRouterKey : Evergreen.V194.Editable.Model
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
    = PressedLogPage (Evergreen.V194.Id.Id Evergreen.V194.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V194.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V194.User.AdminUiSection
    | PressedExpandSection Evergreen.V194.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V194.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V194.Editable.Msg (Maybe Evergreen.V194.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V194.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V194.Editable.Msg Evergreen.V194.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V194.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V194.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
