module Evergreen.V163.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V163.Discord
import Evergreen.V163.Editable
import Evergreen.V163.Id
import Evergreen.V163.LocalState
import Evergreen.V163.NonemptyDict
import Evergreen.V163.Pagination
import Evergreen.V163.SessionIdHash
import Evergreen.V163.Slack
import Evergreen.V163.Table
import Evergreen.V163.User
import Evergreen.V163.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V163.NonemptyDict.NonemptyDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V163.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V163.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) Evergreen.V163.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) Evergreen.V163.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) Evergreen.V163.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) Evergreen.V163.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V163.Pagination.Pagination Evergreen.V163.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V163.SessionIdHash.SessionIdHash (Evergreen.V163.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V163.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
        }
    | ExpandSection Evergreen.V163.User.AdminUiSection
    | CollapseSection Evergreen.V163.User.AdminUiSection
    | LogPageChanged (Evergreen.V163.Id.Id Evergreen.V163.Pagination.PageId) (Evergreen.V163.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V163.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V163.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V163.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    | DeleteGuild (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    | CollapseGuild (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    | HideLog (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    | UnhideLog (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    | DisconnectClient Evergreen.V163.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
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
    { table : Evergreen.V163.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V163.Editable.Model
    , publicVapidKey : Evergreen.V163.Editable.Model
    , privateVapidKey : Evergreen.V163.Editable.Model
    , openRouterKey : Evergreen.V163.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V163.Id.Id Evergreen.V163.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V163.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V163.User.AdminUiSection
    | PressedExpandSection Evergreen.V163.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V163.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V163.Editable.Msg (Maybe Evergreen.V163.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V163.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V163.Editable.Msg Evergreen.V163.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V163.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V163.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
