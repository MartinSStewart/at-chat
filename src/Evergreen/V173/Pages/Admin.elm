module Evergreen.V173.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V173.Discord
import Evergreen.V173.Editable
import Evergreen.V173.Id
import Evergreen.V173.LocalState
import Evergreen.V173.NonemptyDict
import Evergreen.V173.Pagination
import Evergreen.V173.SessionIdHash
import Evergreen.V173.Slack
import Evergreen.V173.Table
import Evergreen.V173.User
import Evergreen.V173.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V173.NonemptyDict.NonemptyDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V173.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V173.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V173.Pagination.Pagination Evergreen.V173.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V173.SessionIdHash.SessionIdHash (Evergreen.V173.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V173.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
        }
    | ExpandSection Evergreen.V173.User.AdminUiSection
    | CollapseSection Evergreen.V173.User.AdminUiSection
    | LogPageChanged (Evergreen.V173.Id.Id Evergreen.V173.Pagination.PageId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V173.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V173.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V173.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    | DeleteGuild (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | CollapseGuild (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    | HideLog (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    | UnhideLog (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    | DisconnectClient Evergreen.V173.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
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
    { table : Evergreen.V173.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V173.Editable.Model
    , publicVapidKey : Evergreen.V173.Editable.Model
    , privateVapidKey : Evergreen.V173.Editable.Model
    , openRouterKey : Evergreen.V173.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V173.Id.Id Evergreen.V173.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V173.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V173.User.AdminUiSection
    | PressedExpandSection Evergreen.V173.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V173.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V173.Editable.Msg (Maybe Evergreen.V173.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V173.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V173.Editable.Msg Evergreen.V173.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V173.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V173.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
