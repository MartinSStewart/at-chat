module Evergreen.V247.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V247.Discord
import Evergreen.V247.Editable
import Evergreen.V247.Id
import Evergreen.V247.LocalState
import Evergreen.V247.NonemptyDict
import Evergreen.V247.Pagination
import Evergreen.V247.Postmark
import Evergreen.V247.SessionIdHash
import Evergreen.V247.Slack
import Evergreen.V247.Table
import Evergreen.V247.ToBackendLog
import Evergreen.V247.User
import Evergreen.V247.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V247.NonemptyDict.NonemptyDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V247.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V247.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V247.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) Evergreen.V247.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V247.Pagination.Pagination Evergreen.V247.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V247.SessionIdHash.SessionIdHash (Evergreen.V247.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V247.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V247.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V247.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
        }
    | ExpandSection Evergreen.V247.User.AdminUiSection
    | CollapseSection Evergreen.V247.User.AdminUiSection
    | LogPageChanged (Evergreen.V247.Id.Id Evergreen.V247.Pagination.PageId) (Evergreen.V247.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V247.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V247.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V247.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V247.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | DeleteGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | RestoreGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | CollapseGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | HideLog (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    | UnhideLog (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    | DisconnectClient Evergreen.V247.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V247.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
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
    { table : Evergreen.V247.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V247.Editable.Model
    , publicVapidKey : Evergreen.V247.Editable.Model
    , privateVapidKey : Evergreen.V247.Editable.Model
    , openRouterKey : Evergreen.V247.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V247.Editable.Model
    , postmarkKey : Evergreen.V247.Editable.Model
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
    = PressedLogPage (Evergreen.V247.Id.Id Evergreen.V247.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V247.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V247.User.AdminUiSection
    | PressedExpandSection Evergreen.V247.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V247.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V247.Editable.Msg (Maybe Evergreen.V247.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V247.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V247.Editable.Msg Evergreen.V247.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V247.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V247.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V247.Editable.Msg Evergreen.V247.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V247.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
