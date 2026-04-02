module Evergreen.V186.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V186.Discord
import Evergreen.V186.Editable
import Evergreen.V186.Id
import Evergreen.V186.LocalState
import Evergreen.V186.NonemptyDict
import Evergreen.V186.Pagination
import Evergreen.V186.SessionIdHash
import Evergreen.V186.Slack
import Evergreen.V186.Table
import Evergreen.V186.User
import Evergreen.V186.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V186.NonemptyDict.NonemptyDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V186.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V186.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) Evergreen.V186.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V186.Pagination.Pagination Evergreen.V186.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V186.SessionIdHash.SessionIdHash (Evergreen.V186.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V186.LocalState.LastRequest)
    , filesCount : Int
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
        }
    | ExpandSection Evergreen.V186.User.AdminUiSection
    | CollapseSection Evergreen.V186.User.AdminUiSection
    | LogPageChanged (Evergreen.V186.Id.Id Evergreen.V186.Pagination.PageId) (Evergreen.V186.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V186.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V186.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V186.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    | DeleteGuild (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | CollapseGuild (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    | HideLog (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    | UnhideLog (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    | DisconnectClient Evergreen.V186.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
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
    { table : Evergreen.V186.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V186.Editable.Model
    , publicVapidKey : Evergreen.V186.Editable.Model
    , privateVapidKey : Evergreen.V186.Editable.Model
    , openRouterKey : Evergreen.V186.Editable.Model
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
    = PressedLogPage (Evergreen.V186.Id.Id Evergreen.V186.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V186.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V186.User.AdminUiSection
    | PressedExpandSection Evergreen.V186.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V186.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V186.Editable.Msg (Maybe Evergreen.V186.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V186.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V186.Editable.Msg Evergreen.V186.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V186.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V186.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
