module Evergreen.V171.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V171.Discord
import Evergreen.V171.Editable
import Evergreen.V171.Id
import Evergreen.V171.LocalState
import Evergreen.V171.NonemptyDict
import Evergreen.V171.Pagination
import Evergreen.V171.SessionIdHash
import Evergreen.V171.Slack
import Evergreen.V171.Table
import Evergreen.V171.User
import Evergreen.V171.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V171.NonemptyDict.NonemptyDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V171.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V171.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) Evergreen.V171.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) Evergreen.V171.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) Evergreen.V171.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) Evergreen.V171.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V171.Pagination.Pagination Evergreen.V171.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V171.SessionIdHash.SessionIdHash (Evergreen.V171.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V171.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
        }
    | ExpandSection Evergreen.V171.User.AdminUiSection
    | CollapseSection Evergreen.V171.User.AdminUiSection
    | LogPageChanged (Evergreen.V171.Id.Id Evergreen.V171.Pagination.PageId) (Evergreen.V171.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V171.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V171.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V171.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    | DeleteGuild (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    | CollapseGuild (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    | HideLog (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    | UnhideLog (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    | DisconnectClient Evergreen.V171.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
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
    { table : Evergreen.V171.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V171.Editable.Model
    , publicVapidKey : Evergreen.V171.Editable.Model
    , privateVapidKey : Evergreen.V171.Editable.Model
    , openRouterKey : Evergreen.V171.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V171.Id.Id Evergreen.V171.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V171.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V171.User.AdminUiSection
    | PressedExpandSection Evergreen.V171.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V171.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V171.Editable.Msg (Maybe Evergreen.V171.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V171.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V171.Editable.Msg Evergreen.V171.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V171.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V171.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
