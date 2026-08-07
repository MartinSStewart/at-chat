module Evergreen.V347.Game exposing (..)

import Array
import Evergreen.V347.Go
import Evergreen.V347.Id
import Evergreen.V347.Message
import Evergreen.V347.SecretId
import Evergreen.V347.UserSession
import Evergreen.V347.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V347.Go.GameMsg
    | GoSetupMsg Evergreen.V347.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V347.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V347.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V347.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V347.Go.ValidatedSetup (Array.Array Evergreen.V347.Go.ActionWithTime) Evergreen.V347.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V347.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V347.WordSpellingGame.ActionWithTime) Evergreen.V347.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.UserSession.ToBeFilledInByBackend (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V347.Go.GameModel
    | WordSpellingGame_Game Evergreen.V347.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V347.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V347.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V347.Go.ValidatedSetup (Array.Array Evergreen.V347.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V347.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V347.WordSpellingGame.ActionWithTime) Evergreen.V347.WordSpellingGame.Shared
