module Evergreen.V216.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V216.Discord
import Evergreen.V216.Editable
import Evergreen.V216.Id
import Evergreen.V216.LocalState
import Evergreen.V216.NonemptyDict
import Evergreen.V216.Pagination
import Evergreen.V216.Postmark
import Evergreen.V216.SessionIdHash
import Evergreen.V216.Slack
import Evergreen.V216.Table
import Evergreen.V216.ToBackendLog
import Evergreen.V216.User
import Evergreen.V216.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V216.NonemptyDict.NonemptyDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V216.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V216.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V216.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V216.Pagination.Pagination Evergreen.V216.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V216.SessionIdHash.SessionIdHash (Evergreen.V216.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V216.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V216.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
        }
    | ExpandSection Evergreen.V216.User.AdminUiSection
    | CollapseSection Evergreen.V216.User.AdminUiSection
    | LogPageChanged (Evergreen.V216.Id.Id Evergreen.V216.Pagination.PageId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V216.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V216.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V216.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V216.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | DeleteGuild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | CollapseGuild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | HideLog (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    | UnhideLog (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    | DisconnectClient Evergreen.V216.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V216.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
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
    { table : Evergreen.V216.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V216.Editable.Model
    , publicVapidKey : Evergreen.V216.Editable.Model
    , privateVapidKey : Evergreen.V216.Editable.Model
    , openRouterKey : Evergreen.V216.Editable.Model
    , postmarkKey : Evergreen.V216.Editable.Model
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
    = PressedLogPage (Evergreen.V216.Id.Id Evergreen.V216.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V216.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V216.User.AdminUiSection
    | PressedExpandSection Evergreen.V216.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V216.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V216.Editable.Msg (Maybe Evergreen.V216.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V216.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V216.Editable.Msg Evergreen.V216.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V216.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V216.Editable.Msg Evergreen.V216.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V216.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
