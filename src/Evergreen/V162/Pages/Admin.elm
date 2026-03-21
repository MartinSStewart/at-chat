module Evergreen.V162.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V162.Discord
import Evergreen.V162.Editable
import Evergreen.V162.Id
import Evergreen.V162.LocalState
import Evergreen.V162.NonemptyDict
import Evergreen.V162.Pagination
import Evergreen.V162.SessionIdHash
import Evergreen.V162.Slack
import Evergreen.V162.Table
import Evergreen.V162.User
import Evergreen.V162.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V162.NonemptyDict.NonemptyDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V162.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V162.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) Evergreen.V162.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) Evergreen.V162.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) Evergreen.V162.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) Evergreen.V162.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V162.Pagination.Pagination Evergreen.V162.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V162.SessionIdHash.SessionIdHash (Evergreen.V162.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V162.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
        }
    | ExpandSection Evergreen.V162.User.AdminUiSection
    | CollapseSection Evergreen.V162.User.AdminUiSection
    | LogPageChanged (Evergreen.V162.Id.Id Evergreen.V162.Pagination.PageId) (Evergreen.V162.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V162.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V162.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V162.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    | DeleteGuild (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    | CollapseGuild (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    | HideLog (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    | UnhideLog (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    | DisconnectClient Evergreen.V162.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
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
    { table : Evergreen.V162.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V162.Editable.Model
    , publicVapidKey : Evergreen.V162.Editable.Model
    , privateVapidKey : Evergreen.V162.Editable.Model
    , openRouterKey : Evergreen.V162.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type Msg
    = PressedLogPage (Evergreen.V162.Id.Id Evergreen.V162.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V162.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V162.User.AdminUiSection
    | PressedExpandSection Evergreen.V162.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V162.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V162.Editable.Msg (Maybe Evergreen.V162.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V162.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V162.Editable.Msg Evergreen.V162.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V162.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V162.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ExportSubset
    = ExportSubset
    | ExportAll


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
