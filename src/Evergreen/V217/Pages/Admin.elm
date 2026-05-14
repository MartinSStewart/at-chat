module Evergreen.V217.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V217.Discord
import Evergreen.V217.Editable
import Evergreen.V217.Id
import Evergreen.V217.LocalState
import Evergreen.V217.NonemptyDict
import Evergreen.V217.Pagination
import Evergreen.V217.Postmark
import Evergreen.V217.SessionIdHash
import Evergreen.V217.Slack
import Evergreen.V217.Table
import Evergreen.V217.ToBackendLog
import Evergreen.V217.User
import Evergreen.V217.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V217.NonemptyDict.NonemptyDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V217.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V217.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V217.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V217.Pagination.Pagination Evergreen.V217.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V217.SessionIdHash.SessionIdHash (Evergreen.V217.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V217.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V217.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
        }
    | ExpandSection Evergreen.V217.User.AdminUiSection
    | CollapseSection Evergreen.V217.User.AdminUiSection
    | LogPageChanged (Evergreen.V217.Id.Id Evergreen.V217.Pagination.PageId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V217.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V217.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V217.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V217.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | DeleteGuild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | CollapseGuild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | HideLog (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    | UnhideLog (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    | DisconnectClient Evergreen.V217.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V217.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
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
    { table : Evergreen.V217.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
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
    | ExportingFinalStep Bytes.Bytes


type alias Model =
    { highlightLog : Maybe (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V217.Editable.Model
    , publicVapidKey : Evergreen.V217.Editable.Model
    , privateVapidKey : Evergreen.V217.Editable.Model
    , openRouterKey : Evergreen.V217.Editable.Model
    , postmarkKey : Evergreen.V217.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V217.Id.Id Evergreen.V217.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V217.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V217.User.AdminUiSection
    | PressedExpandSection Evergreen.V217.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V217.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V217.Editable.Msg (Maybe Evergreen.V217.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V217.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V217.Editable.Msg Evergreen.V217.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V217.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V217.Editable.Msg Evergreen.V217.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V217.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
