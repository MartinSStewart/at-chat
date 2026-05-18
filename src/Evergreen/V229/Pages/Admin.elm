module Evergreen.V229.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V229.Discord
import Evergreen.V229.Editable
import Evergreen.V229.Id
import Evergreen.V229.LocalState
import Evergreen.V229.NonemptyDict
import Evergreen.V229.Pagination
import Evergreen.V229.Postmark
import Evergreen.V229.SessionIdHash
import Evergreen.V229.Slack
import Evergreen.V229.Table
import Evergreen.V229.ToBackendLog
import Evergreen.V229.User
import Evergreen.V229.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V229.NonemptyDict.NonemptyDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V229.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V229.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V229.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) Evergreen.V229.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V229.Pagination.Pagination Evergreen.V229.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V229.SessionIdHash.SessionIdHash (Evergreen.V229.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V229.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V229.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
        }
    | ExpandSection Evergreen.V229.User.AdminUiSection
    | CollapseSection Evergreen.V229.User.AdminUiSection
    | LogPageChanged (Evergreen.V229.Id.Id Evergreen.V229.Pagination.PageId) (Evergreen.V229.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V229.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V229.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V229.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V229.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | DeleteGuild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | CollapseGuild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | HideLog (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    | UnhideLog (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    | DisconnectClient Evergreen.V229.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V229.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
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
    { table : Evergreen.V229.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V229.Editable.Model
    , publicVapidKey : Evergreen.V229.Editable.Model
    , privateVapidKey : Evergreen.V229.Editable.Model
    , openRouterKey : Evergreen.V229.Editable.Model
    , postmarkKey : Evergreen.V229.Editable.Model
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
    = PressedLogPage (Evergreen.V229.Id.Id Evergreen.V229.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V229.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V229.User.AdminUiSection
    | PressedExpandSection Evergreen.V229.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V229.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V229.Editable.Msg (Maybe Evergreen.V229.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V229.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V229.Editable.Msg Evergreen.V229.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V229.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V229.Editable.Msg Evergreen.V229.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V229.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
