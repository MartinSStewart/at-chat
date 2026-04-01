module Evergreen.V184.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V184.Discord
import Evergreen.V184.Editable
import Evergreen.V184.Id
import Evergreen.V184.LocalState
import Evergreen.V184.NonemptyDict
import Evergreen.V184.Pagination
import Evergreen.V184.SessionIdHash
import Evergreen.V184.Slack
import Evergreen.V184.Table
import Evergreen.V184.User
import Evergreen.V184.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V184.NonemptyDict.NonemptyDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V184.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V184.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) Evergreen.V184.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V184.Pagination.Pagination Evergreen.V184.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V184.SessionIdHash.SessionIdHash (Evergreen.V184.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V184.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
        }
    | ExpandSection Evergreen.V184.User.AdminUiSection
    | CollapseSection Evergreen.V184.User.AdminUiSection
    | LogPageChanged (Evergreen.V184.Id.Id Evergreen.V184.Pagination.PageId) (Evergreen.V184.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V184.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V184.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V184.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    | DeleteGuild (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | CollapseGuild (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    | HideLog (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    | UnhideLog (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    | DisconnectClient Evergreen.V184.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
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
    { table : Evergreen.V184.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V184.Editable.Model
    , publicVapidKey : Evergreen.V184.Editable.Model
    , privateVapidKey : Evergreen.V184.Editable.Model
    , openRouterKey : Evergreen.V184.Editable.Model
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
    = PressedLogPage (Evergreen.V184.Id.Id Evergreen.V184.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V184.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V184.User.AdminUiSection
    | PressedExpandSection Evergreen.V184.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V184.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V184.Editable.Msg (Maybe Evergreen.V184.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V184.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V184.Editable.Msg Evergreen.V184.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V184.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V184.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
