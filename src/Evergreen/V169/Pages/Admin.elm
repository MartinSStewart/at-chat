module Evergreen.V169.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V169.Discord
import Evergreen.V169.Editable
import Evergreen.V169.Id
import Evergreen.V169.LocalState
import Evergreen.V169.NonemptyDict
import Evergreen.V169.Pagination
import Evergreen.V169.SessionIdHash
import Evergreen.V169.Slack
import Evergreen.V169.Table
import Evergreen.V169.User
import Evergreen.V169.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V169.NonemptyDict.NonemptyDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V169.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V169.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V169.Pagination.Pagination Evergreen.V169.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V169.SessionIdHash.SessionIdHash (Evergreen.V169.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V169.LocalState.LastRequest)
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
        }
    | ExpandSection Evergreen.V169.User.AdminUiSection
    | CollapseSection Evergreen.V169.User.AdminUiSection
    | LogPageChanged (Evergreen.V169.Id.Id Evergreen.V169.Pagination.PageId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V169.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V169.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V169.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    | DeleteGuild (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | CollapseGuild (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    | HideLog (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    | UnhideLog (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    | DisconnectClient Evergreen.V169.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
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
    { table : Evergreen.V169.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V169.Editable.Model
    , publicVapidKey : Evergreen.V169.Editable.Model
    , privateVapidKey : Evergreen.V169.Editable.Model
    , openRouterKey : Evergreen.V169.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type Msg
    = PressedLogPage (Evergreen.V169.Id.Id Evergreen.V169.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V169.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V169.User.AdminUiSection
    | PressedExpandSection Evergreen.V169.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V169.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V169.Editable.Msg (Maybe Evergreen.V169.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V169.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V169.Editable.Msg Evergreen.V169.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V169.Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V169.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes


type ToFrontend
    = ExportBackendResponse ExportSubset Bytes.Bytes
    | ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportProgress
