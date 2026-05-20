module Evergreen.V242.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V242.Discord
import Evergreen.V242.Editable
import Evergreen.V242.Id
import Evergreen.V242.LocalState
import Evergreen.V242.NonemptyDict
import Evergreen.V242.Pagination
import Evergreen.V242.Postmark
import Evergreen.V242.SessionIdHash
import Evergreen.V242.Slack
import Evergreen.V242.Table
import Evergreen.V242.ToBackendLog
import Evergreen.V242.User
import Evergreen.V242.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V242.NonemptyDict.NonemptyDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V242.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V242.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V242.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) Evergreen.V242.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V242.Pagination.Pagination Evergreen.V242.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V242.SessionIdHash.SessionIdHash (Evergreen.V242.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V242.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V242.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketDisconnects : Array.Array Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
        }
    | ExpandSection Evergreen.V242.User.AdminUiSection
    | CollapseSection Evergreen.V242.User.AdminUiSection
    | LogPageChanged (Evergreen.V242.Id.Id Evergreen.V242.Pagination.PageId) (Evergreen.V242.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V242.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V242.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V242.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V242.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | DeleteGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | RestoreGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | CollapseGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | HideLog (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    | UnhideLog (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    | DisconnectClient Evergreen.V242.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V242.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
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
    { table : Evergreen.V242.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V242.Editable.Model
    , publicVapidKey : Evergreen.V242.Editable.Model
    , privateVapidKey : Evergreen.V242.Editable.Model
    , openRouterKey : Evergreen.V242.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V242.Editable.Model
    , postmarkKey : Evergreen.V242.Editable.Model
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
    = PressedLogPage (Evergreen.V242.Id.Id Evergreen.V242.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V242.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V242.User.AdminUiSection
    | PressedExpandSection Evergreen.V242.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V242.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V242.Editable.Msg (Maybe Evergreen.V242.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V242.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V242.Editable.Msg Evergreen.V242.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V242.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V242.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V242.Editable.Msg Evergreen.V242.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V242.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
