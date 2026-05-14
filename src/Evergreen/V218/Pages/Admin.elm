module Evergreen.V218.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V218.Discord
import Evergreen.V218.Editable
import Evergreen.V218.Id
import Evergreen.V218.LocalState
import Evergreen.V218.NonemptyDict
import Evergreen.V218.Pagination
import Evergreen.V218.Postmark
import Evergreen.V218.SessionIdHash
import Evergreen.V218.Slack
import Evergreen.V218.Table
import Evergreen.V218.ToBackendLog
import Evergreen.V218.User
import Evergreen.V218.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V218.NonemptyDict.NonemptyDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V218.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V218.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V218.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V218.Pagination.Pagination Evergreen.V218.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V218.SessionIdHash.SessionIdHash (Evergreen.V218.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V218.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V218.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
        }
    | ExpandSection Evergreen.V218.User.AdminUiSection
    | CollapseSection Evergreen.V218.User.AdminUiSection
    | LogPageChanged (Evergreen.V218.Id.Id Evergreen.V218.Pagination.PageId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V218.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V218.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V218.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V218.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | DeleteGuild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | CollapseGuild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | HideLog (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    | UnhideLog (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    | DisconnectClient Evergreen.V218.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V218.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
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
    { table : Evergreen.V218.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V218.Editable.Model
    , publicVapidKey : Evergreen.V218.Editable.Model
    , privateVapidKey : Evergreen.V218.Editable.Model
    , openRouterKey : Evergreen.V218.Editable.Model
    , postmarkKey : Evergreen.V218.Editable.Model
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
    = PressedLogPage (Evergreen.V218.Id.Id Evergreen.V218.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V218.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V218.User.AdminUiSection
    | PressedExpandSection Evergreen.V218.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V218.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V218.Editable.Msg (Maybe Evergreen.V218.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V218.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V218.Editable.Msg Evergreen.V218.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V218.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V218.Editable.Msg Evergreen.V218.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V218.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
