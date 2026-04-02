module Evergreen.V187.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V187.Discord
import Evergreen.V187.Editable
import Evergreen.V187.Id
import Evergreen.V187.LocalState
import Evergreen.V187.NonemptyDict
import Evergreen.V187.Pagination
import Evergreen.V187.SessionIdHash
import Evergreen.V187.Slack
import Evergreen.V187.Table
import Evergreen.V187.ToBackendLog
import Evergreen.V187.User
import Evergreen.V187.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V187.NonemptyDict.NonemptyDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V187.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V187.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) Evergreen.V187.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V187.Pagination.Pagination Evergreen.V187.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V187.SessionIdHash.SessionIdHash (Evergreen.V187.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V187.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V187.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
        }
    | ExpandSection Evergreen.V187.User.AdminUiSection
    | CollapseSection Evergreen.V187.User.AdminUiSection
    | LogPageChanged (Evergreen.V187.Id.Id Evergreen.V187.Pagination.PageId) (Evergreen.V187.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V187.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V187.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V187.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    | DeleteGuild (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | CollapseGuild (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    | HideLog (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    | UnhideLog (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    | DisconnectClient Evergreen.V187.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
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
    { table : Evergreen.V187.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V187.Editable.Model
    , publicVapidKey : Evergreen.V187.Editable.Model
    , privateVapidKey : Evergreen.V187.Editable.Model
    , openRouterKey : Evergreen.V187.Editable.Model
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
    = PressedLogPage (Evergreen.V187.Id.Id Evergreen.V187.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V187.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V187.User.AdminUiSection
    | PressedExpandSection Evergreen.V187.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V187.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V187.Editable.Msg (Maybe Evergreen.V187.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V187.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V187.Editable.Msg Evergreen.V187.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V187.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V187.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
