module Evergreen.V175.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V175.Discord
import Evergreen.V175.Editable
import Evergreen.V175.Id
import Evergreen.V175.LocalState
import Evergreen.V175.NonemptyDict
import Evergreen.V175.Pagination
import Evergreen.V175.SessionIdHash
import Evergreen.V175.Slack
import Evergreen.V175.Table
import Evergreen.V175.User
import Evergreen.V175.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V175.NonemptyDict.NonemptyDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V175.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V175.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V175.Pagination.Pagination Evergreen.V175.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V175.SessionIdHash.SessionIdHash (Evergreen.V175.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V175.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
        }
    | ExpandSection Evergreen.V175.User.AdminUiSection
    | CollapseSection Evergreen.V175.User.AdminUiSection
    | LogPageChanged (Evergreen.V175.Id.Id Evergreen.V175.Pagination.PageId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V175.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V175.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V175.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    | DeleteGuild (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | CollapseGuild (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    | HideLog (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    | UnhideLog (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    | DisconnectClient Evergreen.V175.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
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
    { table : Evergreen.V175.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V175.Editable.Model
    , publicVapidKey : Evergreen.V175.Editable.Model
    , privateVapidKey : Evergreen.V175.Editable.Model
    , openRouterKey : Evergreen.V175.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V175.Id.Id Evergreen.V175.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V175.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V175.User.AdminUiSection
    | PressedExpandSection Evergreen.V175.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V175.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V175.Editable.Msg (Maybe Evergreen.V175.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V175.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V175.Editable.Msg Evergreen.V175.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V175.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V175.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
