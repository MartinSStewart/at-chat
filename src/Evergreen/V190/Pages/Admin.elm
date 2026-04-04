module Evergreen.V190.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V190.Discord
import Evergreen.V190.Editable
import Evergreen.V190.Id
import Evergreen.V190.LocalState
import Evergreen.V190.NonemptyDict
import Evergreen.V190.Pagination
import Evergreen.V190.SessionIdHash
import Evergreen.V190.Slack
import Evergreen.V190.Table
import Evergreen.V190.ToBackendLog
import Evergreen.V190.User
import Evergreen.V190.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V190.NonemptyDict.NonemptyDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V190.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V190.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) Evergreen.V190.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V190.Pagination.Pagination Evergreen.V190.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V190.SessionIdHash.SessionIdHash (Evergreen.V190.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V190.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V190.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
        }
    | ExpandSection Evergreen.V190.User.AdminUiSection
    | CollapseSection Evergreen.V190.User.AdminUiSection
    | LogPageChanged (Evergreen.V190.Id.Id Evergreen.V190.Pagination.PageId) (Evergreen.V190.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V190.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V190.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V190.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    | DeleteGuild (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | CollapseGuild (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    | HideLog (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    | UnhideLog (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    | DisconnectClient Evergreen.V190.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
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
    { table : Evergreen.V190.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V190.Editable.Model
    , publicVapidKey : Evergreen.V190.Editable.Model
    , privateVapidKey : Evergreen.V190.Editable.Model
    , openRouterKey : Evergreen.V190.Editable.Model
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
    = PressedLogPage (Evergreen.V190.Id.Id Evergreen.V190.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V190.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V190.User.AdminUiSection
    | PressedExpandSection Evergreen.V190.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V190.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V190.Editable.Msg (Maybe Evergreen.V190.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V190.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V190.Editable.Msg Evergreen.V190.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V190.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V190.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
