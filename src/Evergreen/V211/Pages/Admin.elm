module Evergreen.V211.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V211.Discord
import Evergreen.V211.Editable
import Evergreen.V211.Id
import Evergreen.V211.LocalState
import Evergreen.V211.NonemptyDict
import Evergreen.V211.Pagination
import Evergreen.V211.Postmark
import Evergreen.V211.SessionIdHash
import Evergreen.V211.Slack
import Evergreen.V211.Table
import Evergreen.V211.ToBackendLog
import Evergreen.V211.User
import Evergreen.V211.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V211.NonemptyDict.NonemptyDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V211.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V211.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V211.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) Evergreen.V211.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) Evergreen.V211.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) Evergreen.V211.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) Evergreen.V211.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V211.Pagination.Pagination Evergreen.V211.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V211.SessionIdHash.SessionIdHash (Evergreen.V211.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V211.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V211.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
        }
    | ExpandSection Evergreen.V211.User.AdminUiSection
    | CollapseSection Evergreen.V211.User.AdminUiSection
    | LogPageChanged (Evergreen.V211.Id.Id Evergreen.V211.Pagination.PageId) (Evergreen.V211.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V211.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V211.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V211.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V211.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    | DeleteGuild (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    | CollapseGuild (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    | HideLog (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    | UnhideLog (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    | DisconnectClient Evergreen.V211.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V211.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
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
    { table : Evergreen.V211.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V211.Editable.Model
    , publicVapidKey : Evergreen.V211.Editable.Model
    , privateVapidKey : Evergreen.V211.Editable.Model
    , openRouterKey : Evergreen.V211.Editable.Model
    , postmarkKey : Evergreen.V211.Editable.Model
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
    = PressedLogPage (Evergreen.V211.Id.Id Evergreen.V211.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V211.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V211.User.AdminUiSection
    | PressedExpandSection Evergreen.V211.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V211.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V211.Editable.Msg (Maybe Evergreen.V211.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V211.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V211.Editable.Msg Evergreen.V211.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V211.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V211.Editable.Msg Evergreen.V211.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V211.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
