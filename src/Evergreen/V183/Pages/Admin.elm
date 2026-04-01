module Evergreen.V183.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V183.Discord
import Evergreen.V183.Editable
import Evergreen.V183.Id
import Evergreen.V183.LocalState
import Evergreen.V183.NonemptyDict
import Evergreen.V183.Pagination
import Evergreen.V183.SessionIdHash
import Evergreen.V183.Slack
import Evergreen.V183.Table
import Evergreen.V183.User
import Evergreen.V183.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V183.NonemptyDict.NonemptyDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V183.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V183.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) Evergreen.V183.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V183.Pagination.Pagination Evergreen.V183.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V183.SessionIdHash.SessionIdHash (Evergreen.V183.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V183.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
        }
    | ExpandSection Evergreen.V183.User.AdminUiSection
    | CollapseSection Evergreen.V183.User.AdminUiSection
    | LogPageChanged (Evergreen.V183.Id.Id Evergreen.V183.Pagination.PageId) (Evergreen.V183.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V183.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V183.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V183.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    | DeleteGuild (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | CollapseGuild (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    | HideLog (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    | UnhideLog (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    | DisconnectClient Evergreen.V183.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
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
    { table : Evergreen.V183.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V183.Editable.Model
    , publicVapidKey : Evergreen.V183.Editable.Model
    , privateVapidKey : Evergreen.V183.Editable.Model
    , openRouterKey : Evergreen.V183.Editable.Model
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
    = PressedLogPage (Evergreen.V183.Id.Id Evergreen.V183.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V183.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V183.User.AdminUiSection
    | PressedExpandSection Evergreen.V183.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V183.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V183.Editable.Msg (Maybe Evergreen.V183.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V183.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V183.Editable.Msg Evergreen.V183.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V183.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V183.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
