module Evergreen.V426.Game exposing (..)

import Array
import Evergreen.V426.Go
import Evergreen.V426.Id
import Evergreen.V426.Message
import Evergreen.V426.SecretId
import Evergreen.V426.SheepGame
import Evergreen.V426.UserSession
import Evergreen.V426.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V426.Go.GameMsg
    | GoSetupMsg Evergreen.V426.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V426.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V426.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V426.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V426.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V426.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V426.Go.ValidatedSetup (Array.Array Evergreen.V426.Go.ActionWithTime) Evergreen.V426.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V426.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V426.WordSpellingGame.ActionWithTime) Evergreen.V426.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V426.SheepGame.ValidatedSetup (Array.Array Evergreen.V426.SheepGame.ActionWithTime) Evergreen.V426.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V426.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V426.Go.ValidatedSetup (Array.Array Evergreen.V426.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V426.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V426.WordSpellingGame.ActionWithTime) Evergreen.V426.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V426.SheepGame.ValidatedSetup (Array.Array Evergreen.V426.SheepGame.ActionWithTime) Evergreen.V426.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId))
    | LoadMatch (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V426.Go.GameModel
    | WordSpellingGame_Game Evergreen.V426.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V426.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V426.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V426.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V426.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId, Evergreen.V426.SheepGame.Input ) Int
    }
