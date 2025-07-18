module Evergreen.Migrate.V3 exposing (..)

{-| This migration file was automatically generated by the lamdera compiler.

It includes:

  - A migration for each of the 6 Lamdera core types that has changed
  - A function named `migrate_ModuleName_TypeName` for each changed/custom type

Expect to see:

  - `Unimplementеd` values as placeholders wherever I was unable to figure out a clear migration path for you
  - `@NOTICE` comments for things you should know about, i.e. new custom type constructors that won't get any
    value mappings from the old type by default

You can edit this file however you wish! It won't be generated again.

See <https://dashboard.lamdera.app/docs/evergreen> for more info.

-}

import Array
import Dict
import Evergreen.V1.ChannelName
import Evergreen.V1.Coord
import Evergreen.V1.CssPixels
import Evergreen.V1.EmailAddress
import Evergreen.V1.Emoji
import Evergreen.V1.Geometry.Types
import Evergreen.V1.GuildName
import Evergreen.V1.Id
import Evergreen.V1.Image
import Evergreen.V1.Internal.Model2
import Evergreen.V1.Internal.Teleport
import Evergreen.V1.Local
import Evergreen.V1.LocalState
import Evergreen.V1.Log
import Evergreen.V1.LoginForm
import Evergreen.V1.MessageInput
import Evergreen.V1.NonemptyDict
import Evergreen.V1.NonemptySet
import Evergreen.V1.Pages.Admin
import Evergreen.V1.Pagination
import Evergreen.V1.PersonName
import Evergreen.V1.Point2d
import Evergreen.V1.Ports
import Evergreen.V1.Postmark
import Evergreen.V1.RichText
import Evergreen.V1.Route
import Evergreen.V1.SecretId
import Evergreen.V1.Table
import Evergreen.V1.Touch
import Evergreen.V1.TwoFactorAuthentication
import Evergreen.V1.Types
import Evergreen.V1.Ui.Anim
import Evergreen.V1.User
import Evergreen.V3.ChannelName
import Evergreen.V3.Coord
import Evergreen.V3.CssPixels
import Evergreen.V3.EmailAddress
import Evergreen.V3.Emoji
import Evergreen.V3.Geometry.Types
import Evergreen.V3.GuildName
import Evergreen.V3.Id
import Evergreen.V3.Image
import Evergreen.V3.Internal.Model2
import Evergreen.V3.Internal.Teleport
import Evergreen.V3.Local
import Evergreen.V3.LocalState
import Evergreen.V3.Log
import Evergreen.V3.LoginForm
import Evergreen.V3.MessageInput
import Evergreen.V3.NonemptyDict
import Evergreen.V3.NonemptySet
import Evergreen.V3.Pages.Admin
import Evergreen.V3.Pagination
import Evergreen.V3.PersonName
import Evergreen.V3.Point2d
import Evergreen.V3.Ports
import Evergreen.V3.Postmark
import Evergreen.V3.RichText
import Evergreen.V3.Route
import Evergreen.V3.SecretId
import Evergreen.V3.Table
import Evergreen.V3.Touch
import Evergreen.V3.TwoFactorAuthentication
import Evergreen.V3.Types
import Evergreen.V3.Ui.Anim
import Evergreen.V3.User
import Lamdera.Migrations exposing (..)
import List
import List.Nonempty
import Maybe
import Quantity
import SeqDict
import SeqSet


frontendModel : Evergreen.V1.Types.FrontendModel -> ModelMigration Evergreen.V3.Types.FrontendModel Evergreen.V3.Types.FrontendMsg
frontendModel old =
    ModelReset


backendModel : Evergreen.V1.Types.BackendModel -> ModelMigration Evergreen.V3.Types.BackendModel Evergreen.V3.Types.BackendMsg
backendModel old =
    ModelReset


frontendMsg : Evergreen.V1.Types.FrontendMsg -> MsgMigration Evergreen.V3.Types.FrontendMsg Evergreen.V3.Types.FrontendMsg
frontendMsg old =
    MsgOldValueIgnored


toBackend : Evergreen.V1.Types.ToBackend -> MsgMigration Evergreen.V3.Types.ToBackend Evergreen.V3.Types.BackendMsg
toBackend old =
    MsgOldValueIgnored


backendMsg : Evergreen.V1.Types.BackendMsg -> MsgMigration Evergreen.V3.Types.BackendMsg Evergreen.V3.Types.BackendMsg
backendMsg old =
    MsgOldValueIgnored


toFrontend : Evergreen.V1.Types.ToFrontend -> MsgMigration Evergreen.V3.Types.ToFrontend Evergreen.V3.Types.FrontendMsg
toFrontend old =
    MsgOldValueIgnored
