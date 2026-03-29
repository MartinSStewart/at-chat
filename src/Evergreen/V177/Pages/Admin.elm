module Evergreen.V177.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V177.Discord
import Evergreen.V177.Editable
import Evergreen.V177.Id
import Evergreen.V177.LocalState
import Evergreen.V177.NonemptyDict
import Evergreen.V177.Pagination
import Evergreen.V177.SessionIdHash
import Evergreen.V177.Slack
import Evergreen.V177.Table
import Evergreen.V177.User
import Evergreen.V177.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V177.NonemptyDict.NonemptyDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V177.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V177.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V177.Pagination.Pagination Evergreen.V177.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V177.SessionIdHash.SessionIdHash (Evergreen.V177.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V177.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
        }
    | ExpandSection Evergreen.V177.User.AdminUiSection
    | CollapseSection Evergreen.V177.User.AdminUiSection
    | LogPageChanged (Evergreen.V177.Id.Id Evergreen.V177.Pagination.PageId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V177.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V177.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V177.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    | DeleteGuild (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | CollapseGuild (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    | HideLog (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    | UnhideLog (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    | DisconnectClient Evergreen.V177.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
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
    { table : Evergreen.V177.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V177.Editable.Model
    , publicVapidKey : Evergreen.V177.Editable.Model
    , privateVapidKey : Evergreen.V177.Editable.Model
    , openRouterKey : Evergreen.V177.Editable.Model
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
    = PressedLogPage (Evergreen.V177.Id.Id Evergreen.V177.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V177.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V177.User.AdminUiSection
    | PressedExpandSection Evergreen.V177.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V177.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V177.Editable.Msg (Maybe Evergreen.V177.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V177.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V177.Editable.Msg Evergreen.V177.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V177.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V177.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
