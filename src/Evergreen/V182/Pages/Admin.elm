module Evergreen.V182.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V182.Discord
import Evergreen.V182.Editable
import Evergreen.V182.Id
import Evergreen.V182.LocalState
import Evergreen.V182.NonemptyDict
import Evergreen.V182.Pagination
import Evergreen.V182.SessionIdHash
import Evergreen.V182.Slack
import Evergreen.V182.Table
import Evergreen.V182.User
import Evergreen.V182.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V182.NonemptyDict.NonemptyDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V182.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V182.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) Evergreen.V182.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) Evergreen.V182.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) Evergreen.V182.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) Evergreen.V182.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V182.Pagination.Pagination Evergreen.V182.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V182.SessionIdHash.SessionIdHash (Evergreen.V182.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V182.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
        }
    | ExpandSection Evergreen.V182.User.AdminUiSection
    | CollapseSection Evergreen.V182.User.AdminUiSection
    | LogPageChanged (Evergreen.V182.Id.Id Evergreen.V182.Pagination.PageId) (Evergreen.V182.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V182.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V182.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V182.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    | DeleteGuild (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    | CollapseGuild (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    | HideLog (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    | UnhideLog (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    | DisconnectClient Evergreen.V182.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
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
    { table : Evergreen.V182.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V182.Editable.Model
    , publicVapidKey : Evergreen.V182.Editable.Model
    , privateVapidKey : Evergreen.V182.Editable.Model
    , openRouterKey : Evergreen.V182.Editable.Model
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
    = PressedLogPage (Evergreen.V182.Id.Id Evergreen.V182.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V182.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V182.User.AdminUiSection
    | PressedExpandSection Evergreen.V182.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V182.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V182.Editable.Msg (Maybe Evergreen.V182.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V182.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V182.Editable.Msg Evergreen.V182.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V182.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V182.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
