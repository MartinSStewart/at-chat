module Evergreen.V166.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V166.Discord
import Evergreen.V166.Editable
import Evergreen.V166.Id
import Evergreen.V166.LocalState
import Evergreen.V166.NonemptyDict
import Evergreen.V166.Pagination
import Evergreen.V166.SessionIdHash
import Evergreen.V166.Slack
import Evergreen.V166.Table
import Evergreen.V166.User
import Evergreen.V166.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V166.NonemptyDict.NonemptyDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V166.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V166.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) Evergreen.V166.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V166.Pagination.Pagination Evergreen.V166.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V166.SessionIdHash.SessionIdHash (Evergreen.V166.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V166.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
        }
    | ExpandSection Evergreen.V166.User.AdminUiSection
    | CollapseSection Evergreen.V166.User.AdminUiSection
    | LogPageChanged (Evergreen.V166.Id.Id Evergreen.V166.Pagination.PageId) (Evergreen.V166.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V166.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V166.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V166.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    | DeleteGuild (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | CollapseGuild (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    | HideLog (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    | UnhideLog (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    | DisconnectClient Evergreen.V166.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
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
    { table : Evergreen.V166.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V166.Editable.Model
    , publicVapidKey : Evergreen.V166.Editable.Model
    , privateVapidKey : Evergreen.V166.Editable.Model
    , openRouterKey : Evergreen.V166.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V166.Id.Id Evergreen.V166.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V166.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V166.User.AdminUiSection
    | PressedExpandSection Evergreen.V166.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V166.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V166.Editable.Msg (Maybe Evergreen.V166.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V166.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V166.Editable.Msg Evergreen.V166.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V166.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V166.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
