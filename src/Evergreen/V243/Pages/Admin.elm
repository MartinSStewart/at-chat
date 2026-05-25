module Evergreen.V243.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V243.Discord
import Evergreen.V243.Editable
import Evergreen.V243.Id
import Evergreen.V243.LocalState
import Evergreen.V243.NonemptyDict
import Evergreen.V243.Pagination
import Evergreen.V243.Postmark
import Evergreen.V243.SessionIdHash
import Evergreen.V243.Slack
import Evergreen.V243.Table
import Evergreen.V243.ToBackendLog
import Evergreen.V243.User
import Evergreen.V243.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V243.NonemptyDict.NonemptyDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V243.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V243.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V243.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) Evergreen.V243.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V243.Pagination.Pagination Evergreen.V243.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V243.SessionIdHash.SessionIdHash (Evergreen.V243.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V243.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V243.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
        }
    | ExpandSection Evergreen.V243.User.AdminUiSection
    | CollapseSection Evergreen.V243.User.AdminUiSection
    | LogPageChanged (Evergreen.V243.Id.Id Evergreen.V243.Pagination.PageId) (Evergreen.V243.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V243.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V243.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V243.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V243.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | DeleteGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | RestoreGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | CollapseGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | HideLog (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    | UnhideLog (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    | DisconnectClient Evergreen.V243.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V243.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
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
    { table : Evergreen.V243.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V243.Editable.Model
    , publicVapidKey : Evergreen.V243.Editable.Model
    , privateVapidKey : Evergreen.V243.Editable.Model
    , openRouterKey : Evergreen.V243.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V243.Editable.Model
    , postmarkKey : Evergreen.V243.Editable.Model
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
    = PressedLogPage (Evergreen.V243.Id.Id Evergreen.V243.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V243.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V243.User.AdminUiSection
    | PressedExpandSection Evergreen.V243.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V243.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V243.Editable.Msg (Maybe Evergreen.V243.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V243.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V243.Editable.Msg Evergreen.V243.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V243.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V243.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V243.Editable.Msg Evergreen.V243.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V243.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
