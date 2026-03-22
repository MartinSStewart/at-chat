module Evergreen.V167.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V167.Discord
import Evergreen.V167.Editable
import Evergreen.V167.Id
import Evergreen.V167.LocalState
import Evergreen.V167.NonemptyDict
import Evergreen.V167.Pagination
import Evergreen.V167.SessionIdHash
import Evergreen.V167.Slack
import Evergreen.V167.Table
import Evergreen.V167.User
import Evergreen.V167.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V167.NonemptyDict.NonemptyDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V167.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V167.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) Evergreen.V167.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V167.Pagination.Pagination Evergreen.V167.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V167.SessionIdHash.SessionIdHash (Evergreen.V167.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V167.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
        }
    | ExpandSection Evergreen.V167.User.AdminUiSection
    | CollapseSection Evergreen.V167.User.AdminUiSection
    | LogPageChanged (Evergreen.V167.Id.Id Evergreen.V167.Pagination.PageId) (Evergreen.V167.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V167.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V167.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V167.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    | DeleteGuild (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | CollapseGuild (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    | HideLog (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    | UnhideLog (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    | DisconnectClient Evergreen.V167.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
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
    { table : Evergreen.V167.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V167.Editable.Model
    , publicVapidKey : Evergreen.V167.Editable.Model
    , privateVapidKey : Evergreen.V167.Editable.Model
    , openRouterKey : Evergreen.V167.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V167.Id.Id Evergreen.V167.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V167.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V167.User.AdminUiSection
    | PressedExpandSection Evergreen.V167.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V167.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V167.Editable.Msg (Maybe Evergreen.V167.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V167.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V167.Editable.Msg Evergreen.V167.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V167.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V167.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
