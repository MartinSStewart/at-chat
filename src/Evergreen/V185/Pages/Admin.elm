module Evergreen.V185.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V185.Discord
import Evergreen.V185.Editable
import Evergreen.V185.Id
import Evergreen.V185.LocalState
import Evergreen.V185.NonemptyDict
import Evergreen.V185.Pagination
import Evergreen.V185.SessionIdHash
import Evergreen.V185.Slack
import Evergreen.V185.Table
import Evergreen.V185.User
import Evergreen.V185.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V185.NonemptyDict.NonemptyDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V185.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V185.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) Evergreen.V185.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V185.Pagination.Pagination Evergreen.V185.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V185.SessionIdHash.SessionIdHash (Evergreen.V185.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V185.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
        }
    | ExpandSection Evergreen.V185.User.AdminUiSection
    | CollapseSection Evergreen.V185.User.AdminUiSection
    | LogPageChanged (Evergreen.V185.Id.Id Evergreen.V185.Pagination.PageId) (Evergreen.V185.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V185.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V185.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V185.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    | DeleteGuild (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | CollapseGuild (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    | HideLog (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    | UnhideLog (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    | DisconnectClient Evergreen.V185.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
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
    { table : Evergreen.V185.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V185.Editable.Model
    , publicVapidKey : Evergreen.V185.Editable.Model
    , privateVapidKey : Evergreen.V185.Editable.Model
    , openRouterKey : Evergreen.V185.Editable.Model
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
    = PressedLogPage (Evergreen.V185.Id.Id Evergreen.V185.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V185.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V185.User.AdminUiSection
    | PressedExpandSection Evergreen.V185.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V185.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V185.Editable.Msg (Maybe Evergreen.V185.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V185.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V185.Editable.Msg Evergreen.V185.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V185.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V185.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
