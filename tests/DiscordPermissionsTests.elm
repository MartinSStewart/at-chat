module DiscordPermissionsTests exposing (tests)

import Discord exposing (OptionalData(..), RoleOrUserId(..))
import Expect
import Test exposing (Test)
import UInt64


{-| The guild ID doubles as the @everyone role ID.
-}
guildId : Discord.Id Discord.GuildId
guildId =
    Discord.idFromUInt64 (UInt64.fromInt 1)


ownerId : Discord.Id Discord.UserId
ownerId =
    Discord.idFromUInt64 (UInt64.fromInt 100)


userId : Discord.Id Discord.UserId
userId =
    Discord.idFromUInt64 (UInt64.fromInt 101)


roleId : Int -> Discord.Id Discord.RoleId
roleId n =
    Discord.idFromUInt64 (UInt64.fromInt n)


role : Int -> Discord.Permissions -> Discord.Role
role n permissions =
    { id = roleId n
    , name = "role" ++ String.fromInt n
    , description = Nothing
    , colors = Missing
    , hoist = False
    , icon = Nothing
    , unicodeEmoji = Nothing
    , position = 0
    , permissions = permissions
    , managed = False
    , mentionable = False
    , flags = Missing
    , tags = Missing
    }


viewAndSend : Discord.Permissions
viewAndSend =
    let
        noPermissions =
            Discord.noPermissions
    in
    { noPermissions | viewChannel = True, sendMessages = True }


viewOnly : Discord.Permissions
viewOnly =
    let
        noPermissions =
            Discord.noPermissions
    in
    { noPermissions | viewChannel = True }


denyView : Discord.Overwrite -> Discord.Overwrite
denyView overwrite =
    { overwrite | deny = viewOnly }


allowView : Discord.Overwrite -> Discord.Overwrite
allowView overwrite =
    { overwrite | allow = viewOnly }


emptyOverwrite : RoleOrUserId -> Discord.Overwrite
emptyOverwrite id =
    { id = id, allow = Discord.noPermissions, deny = Discord.noPermissions }


guild : List Discord.Role -> { guildId : Discord.Id Discord.GuildId, ownerId : Discord.Id Discord.UserId, roles : List Discord.Role }
guild roles =
    { guildId = guildId, ownerId = ownerId, roles = roles }


member : List (Discord.Id Discord.RoleId) -> { userId : Discord.Id Discord.UserId, roles : List (Discord.Id Discord.RoleId) }
member roles =
    { userId = userId, roles = roles }


tests : Test
tests =
    Test.describe
        "Discord channel permission tests"
        [ Test.test "Member gets access from the @everyone role" <|
            \_ ->
                Discord.memberHasChannelPermission .viewChannel (guild [ role 1 viewAndSend ]) (member []) []
                    |> Expect.equal True
        , Test.test "Member without the permission has no access" <|
            \_ ->
                Discord.memberHasChannelPermission .viewChannel (guild [ role 1 Discord.noPermissions ]) (member []) []
                    |> Expect.equal False
        , Test.test "@everyone overwrite denies access" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 viewAndSend ])
                    (member [])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 1)) |> denyView ]
                    |> Expect.equal False
        , Test.test "Role overwrite allow overrides @everyone overwrite deny" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 viewAndSend, role 2 Discord.noPermissions ])
                    (member [ roleId 2 ])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 1)) |> denyView
                    , emptyOverwrite (RoleOrUserId_RoleId (roleId 2)) |> allowView
                    ]
                    |> Expect.equal True
        , Test.test "Role overwrite for a role the member doesn't have is ignored" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 viewAndSend, role 2 Discord.noPermissions ])
                    (member [])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 1)) |> denyView
                    , emptyOverwrite (RoleOrUserId_RoleId (roleId 2)) |> allowView
                    ]
                    |> Expect.equal False
        , Test.test "Allow beats deny within the role overwrite step" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 Discord.noPermissions, role 2 Discord.noPermissions, role 3 Discord.noPermissions ])
                    (member [ roleId 2, roleId 3 ])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 2)) |> denyView
                    , emptyOverwrite (RoleOrUserId_RoleId (roleId 3)) |> allowView
                    ]
                    |> Expect.equal True
        , Test.test "Member overwrite deny wins over role overwrite allow" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 viewAndSend, role 2 Discord.noPermissions ])
                    (member [ roleId 2 ])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 2)) |> allowView
                    , emptyOverwrite (RoleOrUserId_UserId userId) |> denyView
                    ]
                    |> Expect.equal False
        , Test.test "The guild owner always has access" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 Discord.noPermissions ])
                    { userId = ownerId, roles = [] }
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 1)) |> denyView ]
                    |> Expect.equal True
        , Test.test "Administrators bypass overwrites" <|
            \_ ->
                let
                    noPermissions =
                        Discord.noPermissions
                in
                Discord.memberHasChannelPermission
                    .viewChannel
                    (guild [ role 1 Discord.noPermissions, role 2 { noPermissions | administrator = True } ])
                    (member [ roleId 2 ])
                    [ emptyOverwrite (RoleOrUserId_RoleId (roleId 1)) |> denyView ]
                    |> Expect.equal True
        , Test.test "Works with a minimal role record (only id and permissions)" <|
            \_ ->
                Discord.memberHasChannelPermission
                    .viewChannel
                    { guildId = guildId
                    , ownerId = ownerId
                    , roles = [ { id = roleId 1, permissions = viewAndSend } ]
                    }
                    (member [])
                    []
                    |> Expect.equal True
        ]
