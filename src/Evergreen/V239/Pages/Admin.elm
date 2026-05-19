module Evergreen.V239.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V239.Discord
import Evergreen.V239.Editable
import Evergreen.V239.Id
import Evergreen.V239.LocalState
import Evergreen.V239.NonemptyDict
import Evergreen.V239.Pagination
import Evergreen.V239.Postmark
import Evergreen.V239.SessionIdHash
import Evergreen.V239.Slack
import Evergreen.V239.Table
import Evergreen.V239.ToBackendLog
import Evergreen.V239.User
import Evergreen.V239.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V239.NonemptyDict.NonemptyDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V239.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V239.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V239.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V239.Pagination.Pagination Evergreen.V239.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V239.SessionIdHash.SessionIdHash (Evergreen.V239.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V239.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V239.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
        }
    | ExpandSection Evergreen.V239.User.AdminUiSection
    | CollapseSection Evergreen.V239.User.AdminUiSection
    | LogPageChanged (Evergreen.V239.Id.Id Evergreen.V239.Pagination.PageId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V239.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V239.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V239.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V239.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | DeleteGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | RestoreGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | CollapseGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | HideLog (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    | UnhideLog (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    | DisconnectClient Evergreen.V239.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V239.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
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
    { table : Evergreen.V239.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V239.Editable.Model
    , publicVapidKey : Evergreen.V239.Editable.Model
    , privateVapidKey : Evergreen.V239.Editable.Model
    , openRouterKey : Evergreen.V239.Editable.Model
    , postmarkKey : Evergreen.V239.Editable.Model
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
    = PressedLogPage (Evergreen.V239.Id.Id Evergreen.V239.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V239.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V239.User.AdminUiSection
    | PressedExpandSection Evergreen.V239.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V239.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V239.Editable.Msg (Maybe Evergreen.V239.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V239.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V239.Editable.Msg Evergreen.V239.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V239.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V239.Editable.Msg Evergreen.V239.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V239.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
