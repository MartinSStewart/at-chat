module Evergreen.V232.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V232.Discord
import Evergreen.V232.Editable
import Evergreen.V232.Id
import Evergreen.V232.LocalState
import Evergreen.V232.NonemptyDict
import Evergreen.V232.Pagination
import Evergreen.V232.Postmark
import Evergreen.V232.SessionIdHash
import Evergreen.V232.Slack
import Evergreen.V232.Table
import Evergreen.V232.ToBackendLog
import Evergreen.V232.User
import Evergreen.V232.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V232.NonemptyDict.NonemptyDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V232.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V232.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V232.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) Evergreen.V232.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V232.Pagination.Pagination Evergreen.V232.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V232.SessionIdHash.SessionIdHash (Evergreen.V232.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V232.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V232.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
        }
    | ExpandSection Evergreen.V232.User.AdminUiSection
    | CollapseSection Evergreen.V232.User.AdminUiSection
    | LogPageChanged (Evergreen.V232.Id.Id Evergreen.V232.Pagination.PageId) (Evergreen.V232.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V232.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V232.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V232.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V232.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | DeleteGuild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | CollapseGuild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | HideLog (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    | UnhideLog (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    | DisconnectClient Evergreen.V232.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V232.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
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
    { table : Evergreen.V232.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V232.Editable.Model
    , publicVapidKey : Evergreen.V232.Editable.Model
    , privateVapidKey : Evergreen.V232.Editable.Model
    , openRouterKey : Evergreen.V232.Editable.Model
    , postmarkKey : Evergreen.V232.Editable.Model
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
    = PressedLogPage (Evergreen.V232.Id.Id Evergreen.V232.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V232.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V232.User.AdminUiSection
    | PressedExpandSection Evergreen.V232.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V232.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V232.Editable.Msg (Maybe Evergreen.V232.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V232.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V232.Editable.Msg Evergreen.V232.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V232.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V232.Editable.Msg Evergreen.V232.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V232.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
