module Evergreen.V214.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V214.Discord
import Evergreen.V214.Editable
import Evergreen.V214.Id
import Evergreen.V214.LocalState
import Evergreen.V214.NonemptyDict
import Evergreen.V214.Pagination
import Evergreen.V214.Postmark
import Evergreen.V214.SessionIdHash
import Evergreen.V214.Slack
import Evergreen.V214.Table
import Evergreen.V214.ToBackendLog
import Evergreen.V214.User
import Evergreen.V214.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V214.NonemptyDict.NonemptyDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V214.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V214.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V214.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) Evergreen.V214.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) Evergreen.V214.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) Evergreen.V214.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) Evergreen.V214.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V214.Pagination.Pagination Evergreen.V214.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V214.SessionIdHash.SessionIdHash (Evergreen.V214.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V214.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V214.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
        }
    | ExpandSection Evergreen.V214.User.AdminUiSection
    | CollapseSection Evergreen.V214.User.AdminUiSection
    | LogPageChanged (Evergreen.V214.Id.Id Evergreen.V214.Pagination.PageId) (Evergreen.V214.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V214.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V214.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V214.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V214.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    | DeleteGuild (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    | CollapseGuild (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    | HideLog (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    | UnhideLog (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    | DisconnectClient Evergreen.V214.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V214.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
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
    { table : Evergreen.V214.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V214.Editable.Model
    , publicVapidKey : Evergreen.V214.Editable.Model
    , privateVapidKey : Evergreen.V214.Editable.Model
    , openRouterKey : Evergreen.V214.Editable.Model
    , postmarkKey : Evergreen.V214.Editable.Model
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
    = PressedLogPage (Evergreen.V214.Id.Id Evergreen.V214.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V214.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V214.User.AdminUiSection
    | PressedExpandSection Evergreen.V214.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V214.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V214.Editable.Msg (Maybe Evergreen.V214.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V214.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V214.Editable.Msg Evergreen.V214.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V214.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V214.Editable.Msg Evergreen.V214.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V214.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
