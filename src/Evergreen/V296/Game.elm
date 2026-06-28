module Evergreen.V296.Game exposing (..)

import Array
import Evergreen.V296.Go
import Evergreen.V296.Id
import Evergreen.V296.Message
import Evergreen.V296.SecretId
import Evergreen.V296.UserSession
import Evergreen.V296.WordSpellingGame


type FrontendGameData
    = FrontendGameData_Go Evergreen.V296.Go.ValidatedSetup (Array.Array Evergreen.V296.Go.ActionWithTime) Evergreen.V296.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V296.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V296.WordSpellingGame.ActionWithTime) Evergreen.V296.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.UserSession.ToBeFilledInByBackend (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.WordSpellingGame.LocalChange


type Model
    = GoModel Evergreen.V296.Go.Model
    | WordSpellingGameModel Evergreen.V296.WordSpellingGame.Model


type BackendGameData
    = GameData_Go Evergreen.V296.Go.ValidatedSetup (Array.Array Evergreen.V296.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V296.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V296.WordSpellingGame.ActionWithTime) Evergreen.V296.WordSpellingGame.Shared


type Msg
    = GoGameMsg Evergreen.V296.Go.GameMsg
    | GoSetupMsg Evergreen.V296.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V296.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V296.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V296.Message.Game
    | NoOpMsg
