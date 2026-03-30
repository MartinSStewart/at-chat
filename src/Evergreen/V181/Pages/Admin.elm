module Evergreen.V181.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V181.Discord
import Evergreen.V181.Editable
import Evergreen.V181.Id
import Evergreen.V181.LocalState
import Evergreen.V181.NonemptyDict
import Evergreen.V181.Pagination
import Evergreen.V181.SessionIdHash
import Evergreen.V181.Slack
import Evergreen.V181.Table
import Evergreen.V181.User
import Evergreen.V181.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V181.NonemptyDict.NonemptyDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V181.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V181.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V181.Pagination.Pagination Evergreen.V181.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V181.SessionIdHash.SessionIdHash (Evergreen.V181.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V181.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
        }
    | ExpandSection Evergreen.V181.User.AdminUiSection
    | CollapseSection Evergreen.V181.User.AdminUiSection
    | LogPageChanged (Evergreen.V181.Id.Id Evergreen.V181.Pagination.PageId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V181.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V181.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V181.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    | DeleteGuild (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | CollapseGuild (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    | HideLog (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    | UnhideLog (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    | DisconnectClient Evergreen.V181.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
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
    { table : Evergreen.V181.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V181.Editable.Model
    , publicVapidKey : Evergreen.V181.Editable.Model
    , privateVapidKey : Evergreen.V181.Editable.Model
    , openRouterKey : Evergreen.V181.Editable.Model
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
    = PressedLogPage (Evergreen.V181.Id.Id Evergreen.V181.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V181.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V181.User.AdminUiSection
    | PressedExpandSection Evergreen.V181.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V181.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V181.Editable.Msg (Maybe Evergreen.V181.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V181.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V181.Editable.Msg Evergreen.V181.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V181.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V181.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
