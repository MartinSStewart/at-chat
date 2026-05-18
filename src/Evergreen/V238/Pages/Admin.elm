module Evergreen.V238.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V238.Discord
import Evergreen.V238.Editable
import Evergreen.V238.Id
import Evergreen.V238.LocalState
import Evergreen.V238.NonemptyDict
import Evergreen.V238.Pagination
import Evergreen.V238.Postmark
import Evergreen.V238.SessionIdHash
import Evergreen.V238.Slack
import Evergreen.V238.Table
import Evergreen.V238.ToBackendLog
import Evergreen.V238.User
import Evergreen.V238.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V238.NonemptyDict.NonemptyDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V238.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V238.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V238.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) Evergreen.V238.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V238.Pagination.Pagination Evergreen.V238.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V238.SessionIdHash.SessionIdHash (Evergreen.V238.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V238.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V238.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
        }
    | ExpandSection Evergreen.V238.User.AdminUiSection
    | CollapseSection Evergreen.V238.User.AdminUiSection
    | LogPageChanged (Evergreen.V238.Id.Id Evergreen.V238.Pagination.PageId) (Evergreen.V238.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V238.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V238.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V238.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V238.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | DeleteGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | CollapseGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | HideLog (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    | UnhideLog (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    | DisconnectClient Evergreen.V238.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V238.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
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
    { table : Evergreen.V238.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V238.Editable.Model
    , publicVapidKey : Evergreen.V238.Editable.Model
    , privateVapidKey : Evergreen.V238.Editable.Model
    , openRouterKey : Evergreen.V238.Editable.Model
    , postmarkKey : Evergreen.V238.Editable.Model
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
    = PressedLogPage (Evergreen.V238.Id.Id Evergreen.V238.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V238.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V238.User.AdminUiSection
    | PressedExpandSection Evergreen.V238.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V238.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V238.Editable.Msg (Maybe Evergreen.V238.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V238.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V238.Editable.Msg Evergreen.V238.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V238.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V238.Editable.Msg Evergreen.V238.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V238.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
