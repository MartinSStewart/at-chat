module Evergreen.V223.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V223.Discord
import Evergreen.V223.Editable
import Evergreen.V223.Id
import Evergreen.V223.LocalState
import Evergreen.V223.NonemptyDict
import Evergreen.V223.Pagination
import Evergreen.V223.Postmark
import Evergreen.V223.SessionIdHash
import Evergreen.V223.Slack
import Evergreen.V223.Table
import Evergreen.V223.ToBackendLog
import Evergreen.V223.User
import Evergreen.V223.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V223.NonemptyDict.NonemptyDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Evergreen.V223.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V223.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V223.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V223.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) Evergreen.V223.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) Evergreen.V223.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) Evergreen.V223.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) Evergreen.V223.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V223.Pagination.Pagination Evergreen.V223.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V223.SessionIdHash.SessionIdHash (Evergreen.V223.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V223.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V223.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
        }
    | ExpandSection Evergreen.V223.User.AdminUiSection
    | CollapseSection Evergreen.V223.User.AdminUiSection
    | LogPageChanged (Evergreen.V223.Id.Id Evergreen.V223.Pagination.PageId) (Evergreen.V223.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V223.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V223.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V223.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V223.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    | DeleteGuild (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    | CollapseGuild (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    | HideLog (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    | UnhideLog (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    | DisconnectClient Evergreen.V223.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V223.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
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
    { table : Evergreen.V223.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V223.Editable.Model
    , publicVapidKey : Evergreen.V223.Editable.Model
    , privateVapidKey : Evergreen.V223.Editable.Model
    , openRouterKey : Evergreen.V223.Editable.Model
    , postmarkKey : Evergreen.V223.Editable.Model
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
    = PressedLogPage (Evergreen.V223.Id.Id Evergreen.V223.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V223.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V223.User.AdminUiSection
    | PressedExpandSection Evergreen.V223.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V223.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V223.Editable.Msg (Maybe Evergreen.V223.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V223.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V223.Editable.Msg Evergreen.V223.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V223.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V223.Editable.Msg Evergreen.V223.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V223.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
