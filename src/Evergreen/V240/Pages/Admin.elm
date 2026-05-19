module Evergreen.V240.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V240.Discord
import Evergreen.V240.Editable
import Evergreen.V240.Id
import Evergreen.V240.LocalState
import Evergreen.V240.NonemptyDict
import Evergreen.V240.Pagination
import Evergreen.V240.Postmark
import Evergreen.V240.SessionIdHash
import Evergreen.V240.Slack
import Evergreen.V240.Table
import Evergreen.V240.ToBackendLog
import Evergreen.V240.User
import Evergreen.V240.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V240.NonemptyDict.NonemptyDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V240.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V240.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkApiKey : Evergreen.V240.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) Evergreen.V240.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) Evergreen.V240.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V240.Pagination.Pagination Evergreen.V240.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V240.SessionIdHash.SessionIdHash (Evergreen.V240.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V240.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V240.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
        }
    | ExpandSection Evergreen.V240.User.AdminUiSection
    | CollapseSection Evergreen.V240.User.AdminUiSection
    | LogPageChanged (Evergreen.V240.Id.Id Evergreen.V240.Pagination.PageId) (Evergreen.V240.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V240.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V240.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V240.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareTurnApiToken (Maybe String)
    | SetPostmarkKey Evergreen.V240.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | DeleteGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | RestoreGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | CollapseGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | HideLog (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    | UnhideLog (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    | DisconnectClient Evergreen.V240.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V240.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
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
    { table : Evergreen.V240.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V240.Editable.Model
    , publicVapidKey : Evergreen.V240.Editable.Model
    , privateVapidKey : Evergreen.V240.Editable.Model
    , openRouterKey : Evergreen.V240.Editable.Model
    , cloudflareTurnApiToken : Evergreen.V240.Editable.Model
    , postmarkKey : Evergreen.V240.Editable.Model
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
    = PressedLogPage (Evergreen.V240.Id.Id Evergreen.V240.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V240.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V240.User.AdminUiSection
    | PressedExpandSection Evergreen.V240.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V240.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V240.Editable.Msg (Maybe Evergreen.V240.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V240.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V240.Editable.Msg Evergreen.V240.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V240.Editable.Msg (Maybe String))
    | CloudflareTurnApiTokenEditableMsg (Evergreen.V240.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V240.Editable.Msg Evergreen.V240.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V240.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
