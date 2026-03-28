module Evergreen.V176.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V176.Discord
import Evergreen.V176.Editable
import Evergreen.V176.Id
import Evergreen.V176.LocalState
import Evergreen.V176.NonemptyDict
import Evergreen.V176.Pagination
import Evergreen.V176.SessionIdHash
import Evergreen.V176.Slack
import Evergreen.V176.Table
import Evergreen.V176.User
import Evergreen.V176.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V176.NonemptyDict.NonemptyDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V176.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V176.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V176.Pagination.Pagination Evergreen.V176.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V176.SessionIdHash.SessionIdHash (Evergreen.V176.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V176.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
        }
    | ExpandSection Evergreen.V176.User.AdminUiSection
    | CollapseSection Evergreen.V176.User.AdminUiSection
    | LogPageChanged (Evergreen.V176.Id.Id Evergreen.V176.Pagination.PageId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V176.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V176.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V176.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    | DeleteGuild (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | CollapseGuild (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    | HideLog (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    | UnhideLog (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    | DisconnectClient Evergreen.V176.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
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
    { table : Evergreen.V176.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V176.Editable.Model
    , publicVapidKey : Evergreen.V176.Editable.Model
    , privateVapidKey : Evergreen.V176.Editable.Model
    , openRouterKey : Evergreen.V176.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V176.Id.Id Evergreen.V176.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V176.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V176.User.AdminUiSection
    | PressedExpandSection Evergreen.V176.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V176.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V176.Editable.Msg (Maybe Evergreen.V176.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V176.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V176.Editable.Msg Evergreen.V176.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V176.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V176.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
